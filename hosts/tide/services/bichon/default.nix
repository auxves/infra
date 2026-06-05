{ config, ... }:
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
        image = "docker.io/rustmailer/bichon:1.5.0@sha256:405dd09749d785b8df276eb771d75c9b6d9485c2ef7d976d90e8fe30518796e3";

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
