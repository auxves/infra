{ pkgs, config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/home-assistant" = { };

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:2024.12.4@sha256:093f4255f1cd1bddabadfb109d5dbf56f87aaa2f419f6c0377f947ed0ab02204";

    volumes = [
      "${paths."services/home-assistant".path}:/config"
      "${pkgs.writeText ".dockerenv" ""}:/.dockerenv"
    ];

    extraOptions = [
      "--device=/dev/ttyACM0"
      "--cap-add=CAP_NET_RAW"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.home-assistant.rule" = "Host(`home.x.auxves.dev`)";
      "traefik.http.services.home-assistant.loadbalancer.server.port" = "8123";
    };
  };
}
