{ config, lib, ... }: {
  options.flake.services = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.services =
    let
      # Alloy and Traefik serve per-host dashboards, so their domains differ
      # per host and hold no single inventory value.
      hostScopedServices = [ "alloy" "traefik" ];

      field = key: if key == "app" then "domain" else "${key}Domain";

      entries = lib.concatMap
        (host:
          let
            apps = lib.filterAttrs (name: _: !(lib.elem name hostScopedServices)) (host.cfg.apps or { });
          in
          lib.concatMap
            (appName:
              lib.mapAttrsToList
                (key: ingress: { app = appName; inherit key; domain = ingress.domain; })
                (apps.${appName}.ingresses or { })
            )
            (lib.attrNames apps)
        )
        (lib.attrValues config.flake.hosts);

      add = acc: entry:
        let
          f = field entry.key;
          app = acc.${entry.app} or { };
          existing = app.${f} or null;
        in
        if existing == null then
          acc // { ${entry.app} = app // { ${f} = entry.domain; }; }
        else if existing == entry.domain then
          acc
        else
          throw "service ${entry.app} has conflicting ${f} values: ${existing} and ${entry.domain}";
    in
    lib.foldl' add { } entries;
}
