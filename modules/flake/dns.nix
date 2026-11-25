{ config, lib, ... }: {
  options.flake.dns.records = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.attrs);
    default = { };
    description = "DNS records keyed by fully-qualified domain name";
  };

  config.flake.dns.records =
    let
      zone = "auxves.dev";

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
          "${host.name}.${zone}" = publicRecords;
          "*.${host.name}.${zone}" = publicRecords;
        } // lib.optionalAttrs (internalRecords != [ ]) {
          "${host.name}.x.${zone}" = internalRecords;
          "*.${host.name}.x.${zone}" = internalRecords;
        } // lib.optionalAttrs (addrs.public.v4 != null) {
          "v4.${host.name}.${zone}" = [{ type = "A"; value = addrs.public.v4; }];
        } // lib.optionalAttrs (addrs.public.v6 != null) {
          "v6.${host.name}.${zone}" = [{ type = "AAAA"; value = addrs.public.v6; }];
        } // lib.optionalAttrs (addrs.internal.v4 != null) {
          "v4.${host.name}.x.${zone}" = [{ type = "A"; value = addrs.internal.v4; }];
        } // lib.optionalAttrs (addrs.internal.v6 != null) {
          "v6.${host.name}.x.${zone}" = [{ type = "AAAA"; value = addrs.internal.v6; }];
        };

      hosts = builtins.filter (host: host.cfg ? meta.addresses) (lib.attrValues config.flake.hosts);

      explicit = {
        "_minecraft._tcp.mc.${zone}" = [{
          type = "SRV";
          value = {
            priority = 0;
            weight = 100;
            port = 25565;
            target = "tide.${zone}.";
          };
        }];
      };
    in
    lib.foldl' lib.recursiveUpdate explicit (builtins.map hostToRecords hosts);
}
