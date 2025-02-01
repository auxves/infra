{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/loki" = { };

  apps.loki = {
    containers = {
      loki = {
        image = "grafana/loki:3.3.2@sha256:8af2de1abbdd7aa92b27c9bcc96f0f4140c9096b507c77921ffddf1c6ad6c48f";
        user = "root:root";

        ports = [ "3100:3100" ];

        volumes = [ "${paths."services/loki".path}:/loki" ];
      };
    };
  };
}
