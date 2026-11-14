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
            image = "tomsquest/docker-radicale:3.9.1.1@sha256:3869c5c013da5d76132cdeaba1fa0804324119d0ef6f3eaaf18f310f64c6bdc9";
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
