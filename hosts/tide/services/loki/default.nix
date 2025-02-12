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
        image = "grafana/loki:3.4.0@sha256:74b8ccbd6e4b4932874742cf3997389592389ea721b3f210aad266486b985a4c";
        user = "root:root";
        volumes = [ "${cfg.volumes.loki.path}:/loki" ];
      };
    };

    ingress = {
      container = "loki";
      port = 3100;
    };
  };
}
