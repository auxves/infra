{ config, lib, pkgs, ... }:
let
  cfg = config.presets.prometheus;

  yaml = pkgs.formats.yaml { };

  configFile = yaml.generate "prometheus.yaml" {
    global.scrape_interval = "15s";

    scrape_configs = [
      {
        job_name = "containers";

        docker_sd_configs = [{
          host = "unix:///var/run/docker.sock";
          refresh_interval = "5s";
        }];

        relabel_configs = [
          {
            source_labels = [ "__meta_docker_container_label_metrics_enable" ];
            action = "keep";
            regex = true;
          }
          {
            source_labels = [ "__meta_docker_container_label_metrics_job" ];
            target_label = "job";
          }
          {
            source_labels = [ "__address__" "__meta_docker_container_label_metrics_port" ];
            action = "replace";
            regex = "([^:]+)(?::\\d+)?;(\\d+)";
            replacement = "$1:$2";
            target_label = "__address__";
          }
          {
            source_labels = [ "__meta_docker_container_label_metrics_scheme" ];
            action = "replace";
            regex = "(https?)";
            target_label = "__scheme__";
          }
          {
            source_labels = [ "__meta_docker_container_label_metrics_path" ];
            action = "replace";
            regex = "(.+)";
            target_label = "__metrics_path__";
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
    ] ++ cfg.configs;
  };
in
{
  options.presets.prometheus = with lib; {
    enable = mkEnableOption "Enable prometheus";

    configs = mkOption {
      type = types.listOf yaml.type;
      default = [ ];
      description = "Additional scrape configs";
    };
  };

  config = lib.mkIf (cfg.enable) {
    containers = {
      prometheus = {
        image = "prom/prometheus:v3.2.0@sha256:5888c188cf09e3f7eebc97369c3b2ce713e844cdbd88ccf36f5047c958aea120";
        user = "root:root";

        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock:ro" # container scraping
          "${config.volumes.prometheus.path}:/prometheus"
          "${configFile}:/etc/prometheus/prometheus.yml:ro"
        ];
      };
    };

    ingress = {
      container = "prometheus";
      port = 9090;
    };
  };
}
