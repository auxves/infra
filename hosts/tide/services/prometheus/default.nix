{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/prometheus" = { };

  virtualisation.oci-containers.containers.prometheus = {
    image = "prom/prometheus:v2.54.1@sha256:f6639335d34a77d9d9db382b92eeb7fc00934be8eae81dbc03b31cfe90411a94";
    user = "root:root";

    volumes = [
      "${paths."services/prometheus".path}:/prometheus"
      "${./prometheus.yaml}:/etc/prometheus/prometheus.yml:ro"
    ];

    extraOptions = [
      "--health-cmd=wget --spider --quiet http://localhost:9090/-/healthy || exit 1"
      "--health-on-failure=stop"
    ];
  };

  virtualisation.oci-containers.containers.node-exporter = {
    image = "quay.io/prometheus/node-exporter:v1.8.2@sha256:4032c6d5bfd752342c3e631c2f1de93ba6b86c41db6b167b9a35372c139e7706";

    extraOptions = [ "--pid=host" ];

    volumes = [ "/:/host:ro,rslave" ];

    cmd = [ "--path.rootfs=/host" ];
  };

  virtualisation.oci-containers.containers.podman-exporter = {
    image = "quay.io/navidys/prometheus-podman-exporter:v1.13.2@sha256:2fc18fd29c1f04a26850a18f9937a8b64e95696d690f2d6338e168b560319485";
    user = "root:root";

    environment = {
      CONTAINER_HOST = "unix:///run/podman/podman.sock";
    };

    volumes = [ "/run/podman/podman.sock:/run/podman/podman.sock:ro" ];
  };
}
