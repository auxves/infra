{ config, ... }:
let
  paths = config.storage.paths;

  hostname = "grafana.x.auxves.dev";
in
{
  storage.paths."services/grafana" = { };

  virtualisation.oci-containers.containers.grafana = {
    image = "grafana/grafana:11.3.1@sha256:fa801ab6e1ae035135309580891e09f7eb94d1abdbd2106bdc288030b028158c";
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
