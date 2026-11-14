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
            image = "docker.io/rustmailer/bichon:2.4.0@sha256:46a222ac4e84957db9e4bb0c20737da675a83bd5ed308fe07cd513a8b86795e2";

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
    }
  ;
}
