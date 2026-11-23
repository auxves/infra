{ inputs, ... }: {
  flake.modules.nixos.tide = { config, ... }:
    let
      cfg = config.apps.forgejo;
    in
    {
      apps.forgejo = {
        volumes = {
          forgejo = { type = "zfs"; };
        };

        containers = {
          forgejo = {
            image = "codeberg.org/forgejo/forgejo:17.0.2@sha256:879f4f10a98e3e167b32cde5f7ae3af0163d50bfacf567559a27a0e95a95670c";

            environment = {
              FORGEJO__SERVER__DOMAIN = cfg.ingresses.app.domain;
              FORGEJO__SERVER__ROOT_URL = "https://${cfg.ingresses.app.domain}/";
            };

            volumes = [
              "${cfg.volumes.forgejo.path}:/data"
            ];
          };
        };

        ingresses = {
          app = {
            type = "public";
            domain = "forge.auxves.dev";
            container = "forgejo";
            port = 3000;
          };
        };
      };

      monitoring.checks = [{
        name = "forgejo";
        group = "services";
        url = "https://${cfg.ingresses.app.domain}";
        interval = "1m";
        alerts = [{ type = "discord"; }];
        conditions = [
          "[STATUS] == 200"
        ];
      }];
    };

  flake.modules.nixos.harpy = {
    imports = [ inputs.self.modules.nixos.forgejo-runner ];
  };
}
