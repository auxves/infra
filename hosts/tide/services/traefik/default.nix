{ lib, config, ... }:
let
  cfg = config.apps.traefik;
in
{
  sops.secrets."traefik/env" = { };

  apps.traefik = {
    volumes = {
      traefik = { type = "zfs"; };
    };

    containers = {
      traefik = {
        image = "traefik:v3.3.2@sha256:e8b170343bb1ab703a956049291ef0d951867bef39839c9b0d70eebda6b2ed29";

        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
          "${cfg.volumes.traefik.path}:/etc/traefik"
          "${./traefik.yaml}:/etc/traefik/traefik.yaml:ro"
        ];

        environmentFiles = [ config.sops.secrets."traefik/env".path ];

        ports = lib.optionals (config.meta.addresses.internal.v6 != null) [
          # Internal
          "[${config.meta.addresses.internal.v6}]:443:443/tcp"
          "[${config.meta.addresses.internal.v6}]:443:443/udp"
        ] ++ lib.optionals (config.meta.addresses.internal.v4 != null) [
          # Internal
          "${config.meta.addresses.internal.v4}:443:443/tcp"
          "${config.meta.addresses.internal.v4}:443:443/udp"
        ] ++ lib.optionals (config.meta.addresses.public.v6 != null) [
          # Public
          "[${config.meta.addresses.public.v6}]:443:8443/tcp"
          "[${config.meta.addresses.public.v6}]:443:8443/udp"
        ] ++ lib.optionals (config.meta.addresses.public.v4 != null) [
          # Public
          "192.168.7.209:443:8443/tcp"
          "192.168.7.209:443:8443/udp"
        ];

        extraOptions = [
          "--health-cmd=traefik healthcheck"
          "--health-on-failure=stop"
        ];

        labels = {
          "traefik.http.routers.traefik.service" = "api@internal";
          "traefik.http.routers.traefik.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.traefik.tls.domains[0].main" = "${config.networking.hostName}.x.auxves.dev";
          "traefik.http.routers.traefik.tls.domains[0].sans" = "*.${config.networking.hostName}.x.auxves.dev";
        };

        metrics.port = 8080;
      };
    };

    ingress = {
      container = "traefik";
      port = 9999;
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 ];
  networking.firewall.allowedUDPPorts = [ 443 ];
}
