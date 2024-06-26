{ pkgs, ... }: {
  disko.devices.zpool.storage.datasets."services/traefik".type = "zfs_fs";

  virtualisation.oci-containers.containers.traefik-internal = {
    image = "traefik:v3.0.3@sha256:a00ced69e41bf2eb475fd0cc70c1be785e4a5f45d693f26360b688c48816717f";
    autoStart = true;

    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "/storage/services/traefik:/etc/traefik"
    ];

    environment = {
      CF_DNS_API_TOKEN_FILE = "/run/secrets/traefik_cloudflare_token";
    };

    extraOptions = [
      "--network=lan:ip=2600:1700:78c0:130f:abcd::1,mac=7e:b1:c5:e2:89:f0"
      "--network=traefik-internal"
      "--secret=traefik_cloudflare_token"
    ];

    cmd = [
      "--api.insecure=true"
      "--entrypoints.web.address=:80"
      "--entrypoints.websecure.address=:443"
      "--entryPoints.websecure.asDefault=true"
      "--entrypoints.websecure.http3=true"
      "--entrypoints.websecure.http.tls.certresolver=letsencrypt"
      "--entrypoints.websecure.http.tls.domains[0].main=x.auxves.dev"
      "--entrypoints.websecure.http.tls.domains[0].sans=*.x.auxves.dev"
      "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      "--providers.docker=true"
      "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
      "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare"
      "--certificatesResolvers.letsencrypt.acme.dnsChallenge.resolvers=1.1.1.1:53,9.9.9.9:53"
      "--certificatesresolvers.letsencrypt.acme.email=me@auxves.dev"
      "--certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/acme.json"
    ];

    labels = {
      "traefik.http.routers.traefik.rule" = "Host(`traefik.x.auxves.dev`)";
      "traefik.http.routers.traefik.service" = "api@internal";
      "traefik.http.services.traefik.loadbalancer.server.port" = "9999";
    };
  };

  systemd.services."podman-network-traefik-internal" = {
    path = [ pkgs.podman ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.podman}/bin/podman network rm -f traefik-internal";
    };

    script = ''
      podman network exists traefik-internal || podman network create traefik-internal --ipv6 --disable-dns
    '';

    partOf = [ "podman-networks.target" ];
    wantedBy = [ "podman-networks.target" ];
  };
}
