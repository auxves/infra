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
        image = "grafana/grafana:12.0.0@sha256:263cbefd5d9b179893c47c415daab4da5c1f3d6770154741eca4f45c81119884";
        user = "root:root";

        volumes = [
          "${cfg.volumes.grafana.path}:/var/lib/grafana"
        ];

        environment = {
          HOSTNAME = cfg.ingresses.app.domain;
          GF_SERVER_ROOT_URL = "https://${cfg.ingresses.app.domain}";
        };
      };
    };

    ingresses = {
      app = {
        domain = "grafana.auxves.dev";
        container = "grafana";
        port = 3000;
      };
    };
  };

  monitoring.checks = [{
    name = "grafana";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
