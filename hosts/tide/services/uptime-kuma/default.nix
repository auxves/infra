{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/uptime-kuma" = { };

  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "louislam/uptime-kuma:1.23.16@sha256:431fee3be822b04861cf0e35daf4beef6b7cb37391c5f26c3ad6e12ce280fe18";

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
