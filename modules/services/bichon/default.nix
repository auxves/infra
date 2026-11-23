{ ... }: {
  flake.modules.nixos.tide = { config, ... }:
    let
      cfg = config.apps.bichon;
    in
    {
      sops.secrets."bichon/env" = { };

      apps.bichon = { lib', ... }: {
        volumes = {
          data = { type = "zfs"; };
        };

        containers = {
          bichon = {
            image = "docker.io/rustmailer/bichon:2.4.3@sha256:5bbc4bb525c0163531056000b6dcb84e90db81b612e4ca8fbc5ea14410538883";

            volumes = [
              "${cfg.volumes.data.path}:/data"
            ];

            environment = {
              BICHON_PUBLIC_URL = "https://${cfg.ingresses.app.domain}";
              BICHON_ROOT_DIR = "/data";
              BICHON_LOG_LEVEL = "info";
            };

            environmentFiles = [ config.sops.secrets."bichon/env".path ];
          };
        };

        ingresses = {
          app = {
            container = "bichon";
            port = 15630;
          };
        };
      };

      monitoring.checks = [{
        name = "bichon";
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
