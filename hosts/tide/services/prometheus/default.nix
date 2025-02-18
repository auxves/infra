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
        image = "prom/prometheus:v3.2.0@sha256:5888c188cf09e3f7eebc97369c3b2ce713e844cdbd88ccf36f5047c958aea120";
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
        image = "quay.io/prometheus/node-exporter:v1.9.0@sha256:c99d7ee4d12a38661788f60d9eca493f08584e2e544bbd3b3fca64749f86b848";
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
