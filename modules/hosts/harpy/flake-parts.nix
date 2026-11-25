{ inputs, config, lib, ... }: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "harpy";

  flake.dns.records =
    let
      addrs = config.flake.hosts.harpy.cfg.meta.addresses;
      zone = "auxves.dev";
      a = value: lib.optional (value != null) { type = "A"; value = value; };
      aaaa = value: lib.optional (value != null) { type = "AAAA"; value = value; };
      public = a addrs.public.v4 ++ aaaa addrs.public.v6;
      internal = a addrs.internal.v4 ++ aaaa addrs.internal.v6;
    in
    lib.filterAttrs (_: records: records != [ ]) {
      "harpy.${zone}" = public;
      "*.harpy.${zone}" = public;
      "harpy.x.${zone}" = internal;
      "*.harpy.x.${zone}" = internal;
      "v4.harpy.${zone}" = a addrs.public.v4;
      "v6.harpy.${zone}" = aaaa addrs.public.v6;
      "v4.harpy.x.${zone}" = a addrs.internal.v4;
      "v6.harpy.x.${zone}" = aaaa addrs.internal.v6;
    };
}
