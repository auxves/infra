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
        image = "docker.io/rustmailer/bichon:1.6.2@sha256:1f15a8e3d64589f2a0d6e486004eb54f345741de6e7d3589d961a07c22ca8e00";

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
