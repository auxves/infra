{ config, lib, ... }:
let
  cfg = config.presets.exporters;
in
{
  options.presets.exporters = with lib; {
    enable = mkEnableOption "Enable exporters";

    node.enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      description = "Enable node exporter";
    };

    podman.enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      description = "Enable podman exporter";
    };
  };

  config = lib.mkIf (cfg.enable) {
    containers = {
      node = lib.mkIf cfg.node.enable {
        image = "quay.io/prometheus/node-exporter:v1.9.1@sha256:d00a542e409ee618a4edc67da14dd48c5da66726bbd5537ab2af9c1dfc442c8a";
        extraOptions = [ "--pid=host" ];
        volumes = [ "/:/host:ro,rslave" ];
        cmd = [ "--path.rootfs=/host" ];

        metrics = {
          job = "node";
          port = 9100;
        };
      };

      podman = lib.mkIf cfg.podman.enable {
        image = "quay.io/navidys/prometheus-podman-exporter:v1.17.0@sha256:cd10138470a79bc03c484204e362895bdeb72f11cd6bffcd4cfbd6a699ee52db";
        user = "root:root";

        cmd = [ "--collector.enable-all" "-w" "app.service,app.component" ];

        environment = {
          CONTAINER_HOST = "unix:///run/podman/podman.sock";
        };

        volumes = [ "/run/podman/podman.sock:/run/podman/podman.sock:ro" ];

        metrics = {
          job = "podman";
          port = 9882;
        };
      };
    };
  };
}
