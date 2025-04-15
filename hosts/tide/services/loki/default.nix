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
        image = "grafana/loki:3.4.3@sha256:5fe9fa99e9a747297cdf0239a5b25d192d8f668bd6505b09beef4dffcab5aac2";
        user = "root:root";
        volumes = [
          "${cfg.volumes.loki.path}:/loki"
          "${./loki.yaml}:/etc/loki/local-config.yaml:ro"
        ];
      };
    };

    ingress = {
      container = "loki";
      port = 3100;
    };
  };

  monitoring.checks = [{
    name = "loki";
    group = "infra";
    url = "https://${cfg.ingress.domain}/ready";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
