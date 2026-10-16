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

        labels = {
          "traefik.http.middlewares.prometheus-auth.basicauth.users" = "prometheus:$2y$05$Yj052mwfrTZR3huMspAVmu6Z3ASEyOPZl4qvvYUr1VpH26dfQo2D6";
        };
      };
    };

    ingresses = {
      app = {
        container = "prometheus";
        port = 9090;
        settings.middlewares = "prometheus-auth@docker";
      };

      unauthenticated = {
        container = "prometheus";

        settings = {
          service = cfg.ingresses.app.settings.service;
          rule = "${cfg.ingresses.app.settings.rule} && Path(`/-/ready`) && Method(`GET`)";
          priority = 100;
        };
      };
    };
  };

  monitoring.checks = [{
    name = "prometheus";
    group = "infra";
    url = "https://${cfg.ingresses.app.domain}/-/ready";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
