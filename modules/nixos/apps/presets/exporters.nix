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
        image = "quay.io/prometheus/node-exporter:v1.10.0@sha256:d464a7e3af9bbd7748e6c48c5d10e646450d8aab2f4732fbac1ae54af9e87b0e";
        extraOptions = [ "--pid=host" ];
        volumes = [ "/:/host:ro,rslave" ];
        cmd = [ "--path.rootfs=/host" ];

        metrics = {
          job = "node";
          port = 9100;
        };
      };

      podman = lib.mkIf cfg.podman.enable {
        image = "quay.io/navidys/prometheus-podman-exporter:v1.19.0@sha256:2c668ea312e866706ddf11e8031271b9e2bedf2d3b45819388638b90efb19f14";
        user = "root:root";

        cmd = [ "--collector.enable-all" "-w" "app.service,app.component" ];

        environment = {
          CONTAINER_HOST = "unix:///run/podman/podman.sock";
        };

        volumes = [ "/run/podman/podman.sock:/run/podman/podman.sock" ];

        metrics = {
          job = "podman";
          port = 9882;
        };
      };
    };
  };
}
