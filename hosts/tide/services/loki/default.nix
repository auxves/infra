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
        image = "grafana/loki:3.5.2@sha256:d0a95e651bb7d0a5a6468035c5b49c52f4678d90d598f853c06716bca102686b";
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
