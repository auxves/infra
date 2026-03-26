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
        image = "grafana/loki:3.6.8@sha256:9db961170b729dc38277963cbb4a79941626388562cc455db61bf85564aa8945";
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
