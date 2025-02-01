{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/traefik" = { };
  sops.secrets."traefik/env" = { };

  apps.traefik = {
    containers = {
      proxy = {
        image = "traefik:v3.3.2@sha256:e8b170343bb1ab703a956049291ef0d951867bef39839c9b0d70eebda6b2ed29";

        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
          "${paths."services/traefik".path}:/etc/traefik"
          "${./traefik.yaml}:/etc/traefik/traefik.yaml:ro"
        ];

        environmentFiles = [ config.sops.secrets."traefik/env".path ];

        ports = [
          # Internal
          "[fd7a:115c:a1e0::3901:1456]:443:443/tcp"
          "[fd7a:115c:a1e0::3901:1456]:443:443/udp"
          "100.126.20.86:443:443/tcp"
          "100.126.20.86:443:443/udp"

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
          "traefik.http.routers.traefik.service" = "api@internal";
        };

        metrics.port = 8080;
      };
    };

    ingress = {
      container = "proxy";
      host = "traefik.x.auxves.dev";
      port = 9999;
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
