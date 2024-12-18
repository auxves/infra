{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/prometheus" = { };

  virtualisation.oci-containers.containers.prometheus = {
    image = "prom/prometheus:v2.55.1@sha256:2659f4c2ebb718e7695cb9b25ffa7d6be64db013daba13e05c875451cf51b0d3";
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
    image = "quay.io/navidys/prometheus-podman-exporter:v1.14.0@sha256:80f1533d35521a8ed3a555b1fffcee1167af8eba3dd3edf443f806dcd4b15be2";
    user = "root:root";

    environment = {
      CONTAINER_HOST = "unix:///run/podman/podman.sock";
    };

    volumes = [ "/run/podman/podman.sock:/run/podman/podman.sock:ro" ];
  };
}
