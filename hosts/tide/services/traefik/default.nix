{ config, ... }:
let
  paths = config.modules.storage.paths;
in
{
  modules.storage.paths."services/traefik" = { };
  sops.secrets."traefik/env" = { };

  virtualisation.oci-containers.containers.traefik = {
    image = "traefik:v3.0.4@sha256:a208c74fd80a566d4ea376053bff73d31616d7af3f1465a7747b8b89ee34d97e";

    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "${paths."services/traefik".path}:/etc/traefik"
      "${./traefik.yaml}:/etc/traefik/traefik.yaml:ro"
    ];

    environmentFiles = [ config.sops.secrets."traefik/env".path ];

    ports = [
      # Internal
      "[fd7a:115c:a1e0::4d01:292e]:443:443/tcp"
      "[fd7a:115c:a1e0::4d01:292e]:443:443/udp"
      "100.108.41.46:443:443/tcp"
      "100.108.41.46:443:443/udp"

      # Public
      "[2600:1700:78c0:130f:2e0:4cff:fe88:9afa]:443:8443/tcp"
      "[2600:1700:78c0:130f:2e0:4cff:fe88:9afa]:443:8443/udp"
      "192.168.7.209:443:8443/tcp"
      "192.168.7.209:443:8443/udp"
    ];

    extraOptions = [
      "--health-cmd=traefik healthcheck"
      "--health-on-failure=stop"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.traefik.rule" = "Host(`traefik.x.auxves.dev`)";
      "traefik.http.routers.traefik.service" = "api@internal";
      "traefik.http.services.traefik.loadbalancer.server.port" = "9999";
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
