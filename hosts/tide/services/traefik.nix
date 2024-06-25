{ pkgs, ... }: {
  disko.devices.zpool.storage.datasets."services/traefik".type = "zfs_fs";

  virtualisation.oci-containers.containers."traefik" = {
    image = "traefik:v3.0.0@sha256:7996bdae8aaa70eaacf2978b6c949de5b68c0a24ddc3e40c06344ecc88cfaea3";
    autoStart = true;

    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "/services/traefik:/data"
    ];

    environment = { };

    extraOptions = [ "--network=lan" "--network=traefik" ];

    cmd = [
      "--api.insecure=true"
      "--entrypoints.web.address=:80"
      "--entrypoints.websecure.address=:443"
      "--entryPoints.websecure.asDefault=true"
      "--entrypoints.websecure.http3=true"
      "--entrypoints.websecure.http.tls.certresolver=letsencrypt"
      "--entrypoints.websecure.http.tls.domains[0].main=auxves.dev"
      "--entrypoints.websecure.http.tls.domains[0].sans=*.auxves.dev"
      "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      "--providers.docker=true"
      "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
      "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare"
      "--certificatesResolvers.letsencrypt.acme.dnsChallenge.resolvers=1.1.1.1:53,9.9.9.9:53"
      "--certificatesresolvers.letsencrypt.acme.email=me@auxves.dev"
      "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
    ];
  };

  systemd.services."podman-network-traefik" = {
    path = [ pkgs.podman ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.podman}/bin/podman network rm -f traefik";
    };

    script = ''
      podman network inspect traefik || podman network create traefik
    '';

    partOf = [ "podman-networks.target" ];
    wantedBy = [ "podman-networks.target" ];
  };
}
