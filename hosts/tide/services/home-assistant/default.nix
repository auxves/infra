{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.9.0@sha256:796615b38398f6e9beac0af7ed0ffe9c9e717b763e6fa6fdb4d25cae79a80987";

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
