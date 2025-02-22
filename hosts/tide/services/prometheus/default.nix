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
          "${cfg.volumes.prometheus.path}:/prometheus"
          "${./prometheus.yml}:/etc/prometheus/prometheus.yml:ro"
        ];

        cmd = [
          "--config.file=/etc/prometheus/prometheus.yml"
          "--storage.tsdb.path=/prometheus"
          "--web.enable-remote-write-receiver"
        ];
      };
    };

    ingress = {
      container = "prometheus";
      port = 9090;
    };
  };
}
