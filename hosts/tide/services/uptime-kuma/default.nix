{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/uptime-kuma" = { };

  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "louislam/uptime-kuma:1.23.14@sha256:efbd17db3c29dcc9e0996b92f1710874f1343415b7b089acd9348ea3175bd595";

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
