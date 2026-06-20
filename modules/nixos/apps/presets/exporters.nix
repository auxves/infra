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
        image = "quay.io/prometheus/node-exporter:v1.11.1@sha256:0f422f62c15f154af8d8572b23d623aebfb10cec73a5c654d18f911f3f9df241";
        extraOptions = [ "--pid=host" ];
        volumes = [ "/:/host:ro,rslave" ];
        cmd = [ "--path.rootfs=/host" ];

        metrics = {
          job = "node";
          port = 9100;
        };
      };

      podman = lib.mkIf cfg.podman.enable {
        image = "quay.io/navidys/prometheus-podman-exporter:v1.21.1@sha256:df2535490628cbbc17263700082e7eb9de8985f44e9d5ede052f2d5b67daf401";
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
