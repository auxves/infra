{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/loki" = { };

  virtualisation.oci-containers.containers.loki = {
    image = "grafana/loki:3.2.1@sha256:09a53b4a4ff81ffcd8f13886df19d33fac7a8d3aaf952e3c7e66cbade5b2fc31";
    user = "root:root";

    volumes = [ "${paths."services/loki".path}:/loki" ];
  };

  virtualisation.oci-containers.containers.promtail = {
    image = "grafana/promtail:3.2.1@sha256:bf617e9d67e80247a59f717f9c1ad388d7d32dc0a1d29abd5799516d15e0a9b5";
    user = "root:root";

    volumes = [
      "/var/log:/var/log:ro"
      "/etc/machine-id:/etc/machine-id:ro"
      "${./promtail.yaml}:/etc/promtail/config.yml:ro"
    ];
  };
}
