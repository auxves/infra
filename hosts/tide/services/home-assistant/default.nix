{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.11.2@sha256:2ddb0ceb186218e6daf423ac26be2e5a6ce1cd430c6064fe82d1d3d70b95cf38";

    volumes = [
      "${paths."services/home-assistant".path}:/config"
    ];

    extraOptions = [ "--device=/dev/ttyACM0" ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.home-assistant.rule" = "Host(`home.x.auxves.dev`)";
      "traefik.http.services.home-assistant.loadbalancer.server.port" = "8123";
    };
  };
}
