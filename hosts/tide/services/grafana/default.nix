{ config, ... }:
let
  paths = config.storage.paths;

  hostname = "grafana.x.auxves.dev";
in
{
  storage.paths."services/grafana" = { };

  virtualisation.oci-containers.containers.grafana = {
    image = "grafana/grafana:11.2.2@sha256:d5133220d770aba5cb655147b619fa8770b90f41d8489a821d33b1cd34d16f89";
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
