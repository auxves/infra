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
        image = "docker.io/rustmailer/bichon:2.3.1@sha256:df1e538382886b87b02feca8d64423733e1ec6b94979484cc2d67a56cf269ba9";

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
