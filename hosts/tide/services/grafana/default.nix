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
        image = "grafana/grafana:11.5.0@sha256:0a2874cf39c6487093c682215f7c7903ed8646d78ae5f911af945d2dfcc0a447";
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
