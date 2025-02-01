{ self
, lib
, writeShellApplication
, python3
, octodns
, octodns-cloudflare
, formats
, linkFarm
}:
let
  env = python3.withPackages (_: [ octodns octodns-cloudflare ]);

  yaml = formats.yaml { };

  calculateZone = name: config:
    let
      applicableHosts = lib.filterHosts (host: host.cfg ? apps);

      ingresses = lib.pipe applicableHosts [
        (builtins.concatMap lib.ingressesOfHost)
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

      records = builtins.map ingressToRecord ingresses;
    in
    lib.foldl' lib.recursiveUpdate config records;

  zones = builtins.listToAttrs (builtins.map
    (path: rec {
      name = lib.removeSuffix ".nix" (builtins.baseNameOf (toString path));
      value = calculateZone name (import path self);
    })
    (lib.readModules ./zones));

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
      type-whitelist = {
        class = "octodns.processor.filter.TypeAllowlistFilter";
        allowlist = [ "A" "AAAA" "SRV" ];
      };
    };

    zones = {
      "*" = {
        sources = [ "zones" ];
        processors = [ "type-whitelist" ];
        targets = [ "cloudflare" ];
      };
    };
  };
in
writeShellApplication {
  name = "deploy-dns";
  runtimeInputs = [ env ];
  text = ''
    exec octodns-sync --config-file=${yaml.generate "octodns.yaml" config} "$@"
  '';
}
