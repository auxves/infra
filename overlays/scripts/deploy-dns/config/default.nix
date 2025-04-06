{ self, lib, formats, linkFarm }:
let
  yaml = formats.yaml { };

  calculateZone = name: config:
    let
      appsHosts = lib.internal.filterHosts (host: host.cfg ? apps);
      metaHosts = lib.internal.filterHosts (host: host.cfg ? meta.addresses);

      ingresses = lib.pipe appsHosts [
        (builtins.concatMap lib.internal.ingressesOfHost)
        (builtins.filter (ingress: lib.hasSuffix name ingress.domain))
        (builtins.filter (ingress: !(lib.hasInfix ".x." ingress.domain)))
      ];

      ingressToRecord = { type, domain, host, ... }: {
        ${lib.removeSuffix ".${name}" domain} = [
          {
            type = "A";
            value = host.cfg.meta.addresses.${type}.v4;
          }
          {
            type = "AAAA";
            value = host.cfg.meta.addresses.${type}.v6;
          }
        ];
      };

      hostToRecords = host:
        let
          addrs = host.cfg.meta.addresses;

          publicRecords = [ ]
            ++ lib.optional (addrs.public.v4 != null) { type = "A"; value = addrs.public.v4; }
            ++ lib.optional (addrs.public.v6 != null) { type = "AAAA"; value = addrs.public.v6; };

          internalRecords = [ ]
            ++ lib.optional (addrs.internal.v4 != null) { type = "A"; value = addrs.internal.v4; }
            ++ lib.optional (addrs.internal.v6 != null) { type = "AAAA"; value = addrs.internal.v6; };
        in
        { } // lib.optionalAttrs (publicRecords != [ ]) {
          "${host.name}" = publicRecords;
          "*.${host.name}" = publicRecords;
        } // lib.optionalAttrs (internalRecords != [ ]) {
          "${host.name}.x" = internalRecords;
          "*.${host.name}.x" = internalRecords;
        };

      records = builtins.map ingressToRecord ingresses
        ++ builtins.map hostToRecords metaHosts;
    in
    lib.foldl' lib.recursiveUpdate config records;

  zones = builtins.listToAttrs (builtins.map
    (path: rec {
      name = lib.removeSuffix ".nix" (builtins.baseNameOf (toString path));
      value = calculateZone name (import path self);
    })
    (lib.internal.readModules ./zones));

  zoneDir = linkFarm "zones" (lib.mapAttrsToList
    (zone: config: {
      name = "${zone}.yaml";
      path = yaml.generate "${zone}.yaml" config;
    })
    zones);

  config = {
    providers = {
      zones = {
        class = "octodns.provider.yaml.YamlProvider";
        directory = zoneDir;
        default_ttl = 300;
        enforce_order = false;
      };

      cloudflare = {
        class = "octodns_cloudflare.CloudflareProvider";
        token = "env/CF_DNS_API_TOKEN";
      };
    };

    processors = {
      ownership.class = "octodns.processor.ownership.OwnershipProcessor";
    };

    zones = {
      "*" = {
        sources = [ "zones" ];
        processors = [ "ownership" ];
        targets = [ "cloudflare" ];
      };
    };
  };
in
linkFarm "octodns-config" [
  { name = "octodns.yaml"; path = yaml.generate "octodns.yaml" config; }
  { name = "zones"; path = zoneDir; }
]
