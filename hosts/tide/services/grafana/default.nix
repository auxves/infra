{ config, ... }:
let
  cfg = config.apps.grafana;
in
{
  apps.grafana = {
    volumes = {
      grafana = { type = "zfs"; };
    };

    containers = {
      grafana = {
        image = "grafana/grafana:11.6.0@sha256:62d2b9d20a19714ebfe48d1bb405086081bc602aa053e28cf6d73c7537640dfb";
        user = "root:root";

        volumes = [
          "${cfg.volumes.grafana.path}:/var/lib/grafana"
        ];

        environment = {
          HOSTNAME = cfg.ingress.domain;
          GF_SERVER_ROOT_URL = "https://${cfg.ingress.domain}";
        };
      };
    };

    ingress = {
      container = "grafana";
      domain = "grafana.auxves.dev";
      port = 3000;
    };
  };

  monitoring.checks = [{
    name = "grafana";
    group = "services";
    url = "https://${cfg.ingress.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
