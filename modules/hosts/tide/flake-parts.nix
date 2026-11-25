{ inputs, config, lib, ... }: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "tide";

  flake.dns.records =
    let
      addrs = config.flake.hosts.tide.cfg.meta.addresses;
      zone = "auxves.dev";

      publicRecords = [ ]
        ++ lib.optional (addrs.public.v4 != null) { type = "A"; value = addrs.public.v4; }
        ++ lib.optional (addrs.public.v6 != null) { type = "AAAA"; value = addrs.public.v6; };

      internalRecords = [ ]
        ++ lib.optional (addrs.internal.v4 != null) { type = "A"; value = addrs.internal.v4; }
        ++ lib.optional (addrs.internal.v6 != null) { type = "AAAA"; value = addrs.internal.v6; };
    in
    { } // lib.optionalAttrs (publicRecords != [ ]) {
      "tide.${zone}" = publicRecords;
      "*.tide.${zone}" = publicRecords;
    } // lib.optionalAttrs (internalRecords != [ ]) {
      "tide.x.${zone}" = internalRecords;
      "*.tide.x.${zone}" = internalRecords;
    } // lib.optionalAttrs (addrs.public.v4 != null) {
      "v4.tide.${zone}" = [{ type = "A"; value = addrs.public.v4; }];
    } // lib.optionalAttrs (addrs.public.v6 != null) {
      "v6.tide.${zone}" = [{ type = "AAAA"; value = addrs.public.v6; }];
    } // lib.optionalAttrs (addrs.internal.v4 != null) {
      "v4.tide.x.${zone}" = [{ type = "A"; value = addrs.internal.v4; }];
    } // lib.optionalAttrs (addrs.internal.v6 != null) {
      "v6.tide.x.${zone}" = [{ type = "AAAA"; value = addrs.internal.v6; }];
    };
}
