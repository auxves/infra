{ config, ... }:
let
  cfg = config.apps.prometheus;
in
{
  apps.prometheus = {
    volumes = {
      prometheus = { type = "zfs"; };
    };

    containers = {
      prometheus = {
        image = "prom/prometheus:v2.55.1@sha256:2659f4c2ebb718e7695cb9b25ffa7d6be64db013daba13e05c875451cf51b0d3";
        user = "root:root";

        ports = [ "9090:9090" ];

        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro" # container scraping
          "${cfg.volumes.prometheus.path}:/prometheus"
          "${./prometheus.yaml}:/etc/prometheus/prometheus.yml:ro"
        ];

        extraOptions = [
          "--health-cmd=wget --spider --quiet http://localhost:9090/-/healthy || exit 1"
          "--health-on-failure=stop"
        ];
      };
    };
  };

  apps.exporters = {
    containers = {
      node = {
        image = "quay.io/prometheus/node-exporter:v1.8.2@sha256:4032c6d5bfd752342c3e631c2f1de93ba6b86c41db6b167b9a35372c139e7706";
        extraOptions = [ "--pid=host" ];
        volumes = [ "/:/host:ro,rslave" ];
        cmd = [ "--path.rootfs=/host" ];

        metrics = {
          job = "node";
          port = 9100;
        };
      };

      podman = {
        image = "quay.io/navidys/prometheus-podman-exporter:v1.14.1@sha256:0976a0f5dea80a1988984d617b7d83efde99d1564a0e820ee3b17d1fb1d19861";
        user = "root:root";

        cmd = [ "--collector.enable-all" "-w" "app.service,app.component" ];

        environment = {
          CONTAINER_HOST = "unix:///run/podman/podman.sock";
        };

        volumes = [ "/run/podman/podman.sock:/run/podman/podman.sock:ro" ];

        metrics = {
          job = "podman";
          port = 9882;
        };
      };
    };
  };
}
