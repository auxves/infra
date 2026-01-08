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
        image = "prom/prometheus:v3.9.1@sha256:1f0f50f06acaceb0f5670d2c8a658a599affe7b0d8e78b898c1035653849a702";
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
