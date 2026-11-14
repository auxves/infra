{ ... }: {
  flake.modules.nixos.tide = { config, ... }:
    let
      cfg = config.apps.radicale;
    in
    {
      apps.radicale = {
        volumes = {
          radicale = { type = "zfs"; };
        };

        containers = {
          radicale = {
            image = "tomsquest/docker-radicale:3.9.1.0@sha256:3acf47502c5e5a92c6a5dba9eeb7174bb7a20c78b0ab9d6a46ff876a4aab2510";
            volumes = [
              "${cfg.volumes.radicale.path}:/data"
              "${./radicale.conf}:/config/config"
            ];
          };
        };

        ingresses = {
          app = {
            domain = "radicale.auxves.dev";
            container = "radicale";
            port = 5232;
          };
        };
      };

      monitoring.checks = [{
        name = "radicale";
        group = "services";
        url = "https://${cfg.ingresses.app.domain}";
        interval = "1m";
        alerts = [{ type = "discord"; }];
        conditions = [
          "[STATUS] == 200"
        ];
      }];
    };
}
