{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.12.1@sha256:ec483debb415123b5ebe49b9e6b5021d055e5f62c832acc094503afa09bb448d";

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
