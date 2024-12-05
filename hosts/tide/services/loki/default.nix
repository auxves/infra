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
    image = "grafana/promtail:3.3.0@sha256:5aa128328d6b0b47a41e1fedd3e5e599c02203c0368d2a2ffc736785ba5a22a3";
    user = "root:root";

    volumes = [
      "/var/log:/var/log:ro"
      "/etc/machine-id:/etc/machine-id:ro"
      "${./promtail.yaml}:/etc/promtail/config.yml:ro"
    ];
  };
}
