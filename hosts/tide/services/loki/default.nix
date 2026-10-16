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
        image = "grafana/loki:3.7.8@sha256:1107dd5274e0ada47e42472b7a7e71f3b2a2fe878878108f3e2f9e51528f0193";
        user = "root:root";
        volumes = [
          "${cfg.volumes.loki.path}:/loki"
          "${./loki.yaml}:/etc/loki/local-config.yaml"
        ];

        labels = {
          "traefik.http.middlewares.loki-auth.basicauth.users" = "loki:$2y$05$Br6FRQBFBO3V3lEvIVMDc.7RkfPDLFwMiuraC/nhkV8XNXsodT9s6";
        };
      };
    };

    ingresses = {
      app = {
        container = "loki";
        port = 3100;
        settings.middlewares = "loki-auth@docker";
      };

      unauthenticated = {
        container = "loki";

        settings = {
          service = cfg.ingresses.app.settings.service;
          rule = "${cfg.ingresses.app.settings.rule} && Path(`/ready`) && Method(`GET`)";
          priority = 100;
        };
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
