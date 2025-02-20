{ self, config, lib, pkgs, ... }:
let
  cfg = config.presets.promtail;

  yaml = pkgs.formats.yaml { };

  configFile = yaml.generate "promtail.yaml" {
    positions.filename = "/data/positions.yaml";

    clients = [{ url = "https://${self.hosts.tide.cfg.apps.loki.ingress.domain}/loki/api/v1/push"; }];

    scrape_configs = [
      {
        job_name = "containers";

        docker_sd_configs = [{
          host = "unix:///var/run/docker.sock";
          refresh_interval = "5s";
        }];

        pipeline_stages = [
          { decolorize = null; }
          {
            multiline = {
              firstline = "^[^\\s]";
              max_wait_time = "1s";
            };
          }
        ];

        relabel_configs = [
          {
            source_labels = [ "__meta_docker_container_label_app_service" ];
            action = "keep";
            regex = ".+";
          }
          {
            source_labels = [ "__meta_docker_container_name" ];
            regex = "/(.*)";
            target_label = "container";
          }
          {
            regex = "__meta_docker_container_label_app_(.+)";
            action = "labelmap";
          }
        ];
      }
    ];
  };
in
{
  options.presets.promtail = with lib; {
    enable = mkEnableOption "Enable promtail";
  };

  config = lib.mkIf (cfg.enable) {
    volumes = {
      data = { type = "ephemeral"; };
    };

    containers = {
      promtail = {
        image = "grafana/promtail:3.4.2@sha256:c6e9a987ca086cbfef945b8ebd708eb09f98b5e78bfb659e4e5a8b3bd604d11b";
        user = "root:root";

        volumes = [
          "${config.volumes.data.path}:/data" # positions persistence
          "/run/podman/podman.sock:/var/run/docker.sock:ro" # container scraping
          "${configFile}:/etc/promtail/config.yml:ro"
        ];
      };
    };
  };
}
