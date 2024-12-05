{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/loki" = { };

  virtualisation.oci-containers.containers.loki = {
    image = "grafana/loki:3.3.1@sha256:7e30f1aa1b17970a29739432b5f3df30bf2b3e4bdfc22e896452c18bcfe017be";
    user = "root:root";

    volumes = [ "${paths."services/loki".path}:/loki" ];
  };

  virtualisation.oci-containers.containers.promtail = {
    image = "grafana/promtail:3.3.1@sha256:f90460fd8f56d1d14846bb871f86c379f6b73d06c6ef6475cc31ea7f62e14887";
    user = "root:root";

    volumes = [
      "/var/log:/var/log:ro"
      "/etc/machine-id:/etc/machine-id:ro"
      "${./promtail.yaml}:/etc/promtail/config.yml:ro"
    ];
  };
}
