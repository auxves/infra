{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/uptime-kuma" = { };

  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "louislam/uptime-kuma:1.23.15@sha256:d8b1b2151256bda3a99e822902fcbeb27b3eca6ef6d93fad25d2062b9fb61ad2";

    volumes = [
      "${paths."services/uptime-kuma".path}:/app/data"
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.uptime-kuma.rule" = "Host(`uptime.x.auxves.dev`)";
      "traefik.http.services.uptime-kuma.loadbalancer.server.port" = "3001";
    };
  };
}
