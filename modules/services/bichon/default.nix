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
            image = "docker.io/rustmailer/bichon:2.4.4@sha256:a282e5abf942a7b761afb48b4b3529f3be4a823f6e32d06b65a3578bd119a980";

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
