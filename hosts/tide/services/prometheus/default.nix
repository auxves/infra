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
        image = "prom/prometheus:v3.2.1@sha256:6927e0919a144aa7616fd0137d4816816d42f6b816de3af269ab065250859a62";
        user = "root:root";

        volumes = [
          "${cfg.volumes.prometheus.path}:/prometheus"
          "${./prometheus.yml}:/etc/prometheus/prometheus.yml:ro"
        ];

        cmd = [
          "--config.file=/etc/prometheus/prometheus.yml"
          "--storage.tsdb.path=/prometheus"
          "--web.enable-remote-write-receiver"
        ];
      };
    };

    ingress = {
      container = "prometheus";
      port = 9090;
    };
  };

  monitoring.checks = [{
    name = "prometheus";
    group = "infra";
    url = "https://${cfg.ingress.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
