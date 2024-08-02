{ config, ... }:
let
  paths = config.storage.paths;

  hostname = "grafana.x.auxves.dev";
in
{
  storage.paths."services/grafana" = { };

  virtualisation.oci-containers.containers.grafana = {
    image = "grafana/grafana:11.1.3@sha256:b23b588cf7cba025ec95efba82e0d8d2e5d549a8b2cb5d50332d4175693c54e0";
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
