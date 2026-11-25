{ inputs, config, lib, ... }: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "tide";

  flake.dns.records =
    let
      host = "tide";
      addrs = config.flake.hosts.${host}.cfg.meta.addresses;
      zone = "auxves.dev";
      a = value: lib.optional (value != null) { type = "A"; value = value; };
      aaaa = value: lib.optional (value != null) { type = "AAAA"; value = value; };
      public = a addrs.public.v4 ++ aaaa addrs.public.v6;
      internal = a addrs.internal.v4 ++ aaaa addrs.internal.v6;
    in
    lib.filterAttrs (_: records: records != [ ]) {
      "${host}.${zone}" = public;
      "*.${host}.${zone}" = public;
      "${host}.x.${zone}" = internal;
      "*.${host}.x.${zone}" = internal;
      "v4.${host}.${zone}" = a addrs.public.v4;
      "v6.${host}.${zone}" = aaaa addrs.public.v6;
      "v4.${host}.x.${zone}" = a addrs.internal.v4;
      "v6.${host}.x.${zone}" = aaaa addrs.internal.v6;
    };
}
