{ config, ... }:
let
  cfg = config.apps.prometheus;
in
{
  apps.prometheus = {
    volumes = {
      prometheus = { type = "ephemeral"; };
    };

    containers = {
      prometheus = {
        image = "prom/prometheus:v3.1.0@sha256:6559acbd5d770b15bb3c954629ce190ac3cbbdb2b7f1c30f0385c4e05104e218";
        user = "root:root";

        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro" # container scraping
          "${cfg.volumes.prometheus.path}:/prometheus"
          "${./prometheus.yaml}:/etc/prometheus/prometheus.yml:ro"
        ];
      };
    };

    ingress = {
      container = "prometheus";
      port = 9090;
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
