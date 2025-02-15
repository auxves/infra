{ config, ... }:
let
  cfg = config.apps.loki;
in
{
  apps.loki = {
    volumes = {
      loki = { type = "zfs"; };
    };

    containers = {
      loki = {
        image = "grafana/loki:3.4.1@sha256:1d0c5ddc7644b88956aa0bd775ad796d9635180258a225d6ab3552751d5e2a66";
        user = "root:root";
        volumes = [
          "${cfg.volumes.loki.path}:/loki"
          "${./loki.yaml}:/etc/loki/local-config.yaml:ro"
        ];
      };
    };

    ingress = {
      container = "loki";
      port = 3100;
    };
  };
}
