{ config, ... }:
let
  paths = config.storage.paths;

  hostname = "grafana.x.auxves.dev";
in
{
  storage.paths."services/grafana" = { };

  virtualisation.oci-containers.containers.grafana = {
    image = "grafana/grafana:11.3.0@sha256:a0f881232a6fb71a0554a47d0fe2203b6888fe77f4cefb7ea62bed7eb54e13c3";
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
}
