{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."var/cache/traefik" = {
    backend = "local";
  };

  sops.secrets."traefik/env" = { };

  virtualisation.oci-containers.containers.traefik = {
    image = "traefik:v3.3.2@sha256:e8b170343bb1ab703a956049291ef0d951867bef39839c9b0d70eebda6b2ed29";

    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "${paths."var/cache/traefik".path}:/etc/traefik"
      "${./traefik.yaml}:/etc/traefik/traefik.yaml:ro"
    ];

    environmentFiles = [ config.sops.secrets."traefik/env".path ];

    ports = [
      # Internal
      "[fd7a:115c:a1e0::e701:4a12]:443:443/tcp"
      "[fd7a:115c:a1e0::e701:4a12]:443:443/udp"
      "100.92.74.18:443:443/tcp"
      "100.92.74.18:443:443/udp"
    ];

    extraOptions = [
      "--health-cmd=traefik healthcheck"
      "--health-on-failure=stop"
    ];
  };
}
