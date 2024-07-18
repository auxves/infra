{ config, ... }:
let
  paths = config.modules.storage.paths;
in
{
  modules.storage.paths."services/prometheus" = { };

  virtualisation.oci-containers.containers.prometheus = {
    image = "prom/prometheus:v2.53.0@sha256:075b1ba2c4ebb04bc3a6ab86c06ec8d8099f8fda1c96ef6d104d9bb1def1d8bc";
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
    image = "quay.io/prometheus/node-exporter:v1.8.1@sha256:fa7fa12a57eff607176d5c363d8bb08dfbf636b36ac3cb5613a202f3c61a6631";

    extraOptions = [ "--pid=host" ];

    volumes = [ "/:/host:ro,rslave" ];

    cmd = [ "--path.rootfs=/host" ];
  };
}
