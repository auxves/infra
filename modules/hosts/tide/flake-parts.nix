{ inputs, config, lib, ... }: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "tide";

  flake.dns.records =
    let
      addrs = config.flake.hosts.tide.cfg.meta.addresses;
      zone = "auxves.dev";
      a = value: lib.optional (value != null) { type = "A"; value = value; };
      aaaa = value: lib.optional (value != null) { type = "AAAA"; value = value; };
      public = a addrs.public.v4 ++ aaaa addrs.public.v6;
      internal = a addrs.internal.v4 ++ aaaa addrs.internal.v6;
    in
    lib.filterAttrs (_: records: records != [ ]) {
      "tide.${zone}" = public;
      "*.tide.${zone}" = public;
      "tide.x.${zone}" = internal;
      "*.tide.x.${zone}" = internal;
      "v4.tide.${zone}" = a addrs.public.v4;
      "v6.tide.${zone}" = aaaa addrs.public.v6;
      "v4.tide.x.${zone}" = a addrs.internal.v4;
      "v6.tide.x.${zone}" = aaaa addrs.internal.v6;
    };
}
