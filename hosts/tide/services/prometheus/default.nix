{ config, ... }:
let
  cfg = config.apps.prometheus;
in
{
  apps.prometheus = {
    volumes = {
      prometheus = { type = "zfs"; };
    };

    containers = {
      prometheus = {
        image = "prom/prometheus:v3.7.0@sha256:29c1e0b48ad816750245dea3d65ac3ce57dda30547e67b1e9a5176e2953cc4dc";
        user = "root:root";

        volumes = [
          "${cfg.volumes.prometheus.path}:/prometheus"
          "${./prometheus.yml}:/etc/prometheus/prometheus.yml"
        ];

        cmd = [
          "--config.file=/etc/prometheus/prometheus.yml"
          "--storage.tsdb.path=/prometheus"
          "--web.enable-remote-write-receiver"
        ];
      };
    };

    ingresses = {
      app = {
        container = "prometheus";
        port = 9090;
      };
    };
  };

  monitoring.checks = [{
    name = "prometheus";
    group = "infra";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
