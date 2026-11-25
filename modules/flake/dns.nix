{ lib, ... }: {
  options.flake.dns.records = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.attrs);
    default = { };
    description = "DNS records keyed by fully-qualified domain name";
  };
}
