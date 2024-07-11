{ config, ... }:
let
  paths = config.modules.storage.paths;
in
{
  modules.storage.paths."services/uptime-kuma" = { };

  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "louislam/uptime-kuma:1.23.13@sha256:96510915e6be539b76bcba2e6873591c67aca8a6075ff09f5b4723ae47f333fc";

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
