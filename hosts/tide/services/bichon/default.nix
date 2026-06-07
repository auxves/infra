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
        image = "docker.io/rustmailer/bichon:1.5.1@sha256:a521250e880fcbef942a265eb0d97491cb1c94eed71c03c0288a54b4cd16c2bf";

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
