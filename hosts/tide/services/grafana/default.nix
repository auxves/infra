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
        image = "grafana/grafana:13.1.1@sha256:7cb8c64c4d57a57e734073f3cc94620adb24a0acb929bd80ba9f14017e3a975b";
        user = "root:root";

        volumes = [
          "${cfg.volumes.grafana.path}:/var/lib/grafana"
        ];

        environment = {
          HOSTNAME = cfg.ingresses.app.domain;
          GF_SERVER_ROOT_URL = "https://${cfg.ingresses.app.domain}";
          GF_ANALYTICS_REPORTING_ENABLED = "false";
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
