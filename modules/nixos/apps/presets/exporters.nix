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
        image = "quay.io/prometheus/node-exporter:v1.9.0@sha256:c99d7ee4d12a38661788f60d9eca493f08584e2e544bbd3b3fca64749f86b848";
        extraOptions = [ "--pid=host" ];
        volumes = [ "/:/host:ro,rslave" ];
        cmd = [ "--path.rootfs=/host" ];

        metrics = {
          job = "node";
          port = 9100;
        };
      };

      podman = lib.mkIf cfg.podman.enable {
        image = "quay.io/navidys/prometheus-podman-exporter:v1.14.1@sha256:0976a0f5dea80a1988984d617b7d83efde99d1564a0e820ee3b17d1fb1d19861";
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
