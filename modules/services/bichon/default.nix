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
            image = "docker.io/rustmailer/bichon:2.4.1@sha256:506280b132478ae5aaf45aaa2e53ff1e4afcd725f4783838f2605235b0ea4f49";

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
