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
        image = "docker.io/rustmailer/bichon:0.3.6@sha256:4b4099756e612014d9b5575a70d05971be0cfed2ac86b590fd771bb547f95c47";

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
