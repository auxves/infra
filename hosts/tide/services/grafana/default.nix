{ config, ... }:
let
  paths = config.storage.paths;

  hostname = "grafana.x.auxves.dev";
in
{
  storage.paths."services/grafana" = { };

  virtualisation.oci-containers.containers.grafana = {
    image = "grafana/grafana:11.5.0@sha256:0a2874cf39c6487093c682215f7c7903ed8646d78ae5f911af945d2dfcc0a447";
    user = "root:root";

    volumes = [
      "${paths."services/grafana".path}:/var/lib/grafana"
    ];

    environment = {
      HOSTNAME = hostname;
      GF_SERVER_ROOT_URL = "https://${hostname}";
    };

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.grafana.rule" = "Host(`${hostname}`)";
      "traefik.http.services.grafana.loadbalancer.server.port" = "3000";
    };
  };

  monitoring.checks = [{
    name = "grafana";
    group = "services";
    url = "https://${hostname}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
