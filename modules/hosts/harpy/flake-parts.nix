{ inputs, config, lib, ... }: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "harpy";

  flake.dns.records =
    let
      addrs = config.flake.hosts.harpy.cfg.meta.addresses;
      zone = "auxves.dev";

      publicRecords = [ ]
        ++ lib.optional (addrs.public.v4 != null) { type = "A"; value = addrs.public.v4; }
        ++ lib.optional (addrs.public.v6 != null) { type = "AAAA"; value = addrs.public.v6; };

      internalRecords = [ ]
        ++ lib.optional (addrs.internal.v4 != null) { type = "A"; value = addrs.internal.v4; }
        ++ lib.optional (addrs.internal.v6 != null) { type = "AAAA"; value = addrs.internal.v6; };
    in
    { } // lib.optionalAttrs (publicRecords != [ ]) {
      "harpy.${zone}" = publicRecords;
      "*.harpy.${zone}" = publicRecords;
    } // lib.optionalAttrs (internalRecords != [ ]) {
      "harpy.x.${zone}" = internalRecords;
      "*.harpy.x.${zone}" = internalRecords;
    } // lib.optionalAttrs (addrs.public.v4 != null) {
      "v4.harpy.${zone}" = [{ type = "A"; value = addrs.public.v4; }];
    } // lib.optionalAttrs (addrs.public.v6 != null) {
      "v6.harpy.${zone}" = [{ type = "AAAA"; value = addrs.public.v6; }];
    } // lib.optionalAttrs (addrs.internal.v4 != null) {
      "v4.harpy.x.${zone}" = [{ type = "A"; value = addrs.internal.v4; }];
    } // lib.optionalAttrs (addrs.internal.v6 != null) {
      "v6.harpy.x.${zone}" = [{ type = "AAAA"; value = addrs.internal.v6; }];
    };
}
