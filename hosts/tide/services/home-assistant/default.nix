{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.10.0@sha256:2c1b61c2321f2872ed5e2266b5e94a0b2bdbf70b695cb8ed783abc900154ba00";

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
