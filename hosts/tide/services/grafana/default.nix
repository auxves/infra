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
        image = "grafana/grafana:11.5.2@sha256:8b37a2f028f164ce7b9889e1765b9d6ee23fec80f871d156fbf436d6198d32b7";
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
