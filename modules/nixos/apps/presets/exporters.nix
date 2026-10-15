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
        image = "quay.io/prometheus/node-exporter:v1.12.1@sha256:1b4e4438faca4dd7e001dd445d161a4a2091b0fededa84093b3a8dfeae1f1be0";
        extraOptions = [ "--pid=host" ];
        volumes = [
          "/:/host:ro,rslave"
          # D-Bus access for the systemd collector (node_systemd_unit_state)
          "/run/dbus/system_bus_socket:/run/dbus/system_bus_socket:ro"
        ];
        cmd = [
          "--path.rootfs=/host"
          # Explicitly enable the systemd collector (node_systemd_unit_state)
          "--collector.systemd"
        ];

        metrics = {
          job = "node";
          port = 9100;
        };
      };

      podman = lib.mkIf cfg.podman.enable {
        image = "quay.io/navidys/prometheus-podman-exporter:v2.0.0@sha256:ddaa9003e86f435f2d958ab68041959e4d2bb290a350a2649a123c449db032db";
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
