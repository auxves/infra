{ self, lib, formats, linkFarm }:
let
  yaml = formats.yaml { };

  zoneOf = fqdn:
    let parts = lib.splitString "." fqdn;
    in lib.concatStringsSep "." (lib.drop (builtins.length parts - 2) parts);

  zones = lib.unique (builtins.map zoneOf (builtins.attrNames self.dns.records));

  calculateZone = name:
    lib.mapAttrs'
      (domain: records: lib.nameValuePair (lib.removeSuffix ".${name}" domain) records)
      (lib.filterAttrs (domain: _: lib.hasSuffix ".${name}" domain) self.dns.records);

  zoneConfigs = lib.genAttrs zones calculateZone;

  zoneDir = linkFarm "zones" (lib.mapAttrsToList
    (zone: config: {
      name = "${zone}.yaml";
      path = yaml.generate "${zone}.yaml" config;
    })
    zoneConfigs);

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
