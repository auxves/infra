{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/prometheus" = { };

  virtualisation.oci-containers.containers.prometheus = {
    image = "prom/prometheus:v2.53.1@sha256:f20d3127bf2876f4a1df76246fca576b41ddf1125ed1c546fbd8b16ea55117e6";
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
    image = "quay.io/navidys/prometheus-podman-exporter:v1.13.0@sha256:b09cbe4d6a76d07aba23bb5de6945932be3adb8b91e64bd87b97709b80729f32";
    user = "root:root";

    environment = {
      CONTAINER_HOST = "unix:///run/podman/podman.sock";
    };

    volumes = [ "/run/podman/podman.sock:/run/podman/podman.sock:ro" ];
  };
}
