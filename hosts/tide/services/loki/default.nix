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
        image = "grafana/loki:3.3.2@sha256:8af2de1abbdd7aa92b27c9bcc96f0f4140c9096b507c77921ffddf1c6ad6c48f";
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
