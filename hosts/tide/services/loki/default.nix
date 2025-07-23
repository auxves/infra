{ config, ... }:
let
  cfg = config.apps.loki;
in
{
  apps.loki = {
    volumes = {
      loki = { type = "zfs"; };
    };

    containers = {
      loki = {
        image = "grafana/loki:3.5.3@sha256:3165cecce301ce5b9b6e3530284b080934a05cd5cafac3d3d82edcb887b45ecd";
        user = "root:root";
        volumes = [
          "${cfg.volumes.loki.path}:/loki"
          "${./loki.yaml}:/etc/loki/local-config.yaml"
        ];
      };
    };

    ingresses = {
      app = {
        container = "loki";
        port = 3100;
      };
    };
  };

  monitoring.checks = [{
    name = "loki";
    group = "infra";
    url = "https://${cfg.ingresses.app.domain}/ready";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
