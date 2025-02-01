{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/grafana" = { };

  apps.grafana = {
    containers = {
      app = {
        image = "grafana/grafana:11.5.0@sha256:0a2874cf39c6487093c682215f7c7903ed8646d78ae5f911af945d2dfcc0a447";
        user = "root:root";

        volumes = [
          "${paths."services/grafana".path}:/var/lib/grafana"
        ];

        environment = {
          HOSTNAME = config.apps.grafana.ingress.host;
          GF_SERVER_ROOT_URL = "https://${config.apps.grafana.ingress.host}";
        };
      };
    };

    ingress = {
      container = "app";
      host = "grafana.x.auxves.dev";
      port = 3000;
    };
  };

  monitoring.checks = [{
    name = "grafana";
    group = "services";
    url = "https://${config.apps.grafana.ingress.host}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
