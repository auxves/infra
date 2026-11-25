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
            image = "tomsquest/docker-radicale:3.9.2.0@sha256:cc586f75ec709d45d15dfbf20e53bab99e85ee5a4d7beafc7bbf852b2f07a2da";
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
