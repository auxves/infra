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
        image = "prom/prometheus:v3.15.0@sha256:efd719c99d83b060d9daefdcf00360461adf279f45ef5391f8d111892118753e";
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
