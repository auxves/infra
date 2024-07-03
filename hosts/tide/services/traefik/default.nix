{ config, ... }: {
  disko.devices.zpool.storage.datasets."services/traefik".type = "zfs_fs";

  sops.secrets."cloudflare/dns_token" = { };

  virtualisation.oci-containers.containers.traefik = {
    image = "traefik:v3.0.3@sha256:a00ced69e41bf2eb475fd0cc70c1be785e4a5f45d693f26360b688c48816717f";
    autoStart = true;

    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "/storage/services/traefik:/etc/traefik"
      "${./traefik.yaml}:/etc/traefik/traefik.yaml:ro"
      "${config.sops.secrets."cloudflare/dns_token".path}:/run/secrets/cloudflare_token:ro"
    ];

    environment = {
      CF_DNS_API_TOKEN_FILE = "/run/secrets/cloudflare_token";
    };

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
