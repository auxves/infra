{ config, ... }:
let
  cfg = config.apps.promtail;
in
{
  apps.promtail = {
    volumes = {
      data = { type = "ephemeral"; };
    };

    containers = {
      promtail = {
        image = "grafana/promtail:3.4.2@sha256:c6e9a987ca086cbfef945b8ebd708eb09f98b5e78bfb659e4e5a8b3bd604d11b";
        user = "root:root";

        volumes = [
          "${cfg.volumes.data.path}:/data" # positions persistence
          # "/var/log:/var/log:ro" # journal scraping
          # "/etc/machine-id:/etc/machine-id:ro"
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro" # container scraping
          "${./promtail.yaml}:/etc/promtail/config.yml:ro"
        ];
      };
    };
  };
}
