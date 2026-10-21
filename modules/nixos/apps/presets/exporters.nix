{ config, lib, pkgs, ... }:
let
  presetCfg = config.presets.apps.exporters;

  textfileDir = "/var/lib/node-exporter/textfile";

  # A host that can use ZFS declares it in boot.supportedFilesystems;
  # the writer exists only there.
  supportsZfs = config.boot.supportedFilesystems ? zfs;
in
{
  options.presets.apps.exporters = with lib; {
    enable = mkEnableOption "Enable exporters";

    node.enable = mkOption {
      type = types.bool;
      default = presetCfg.enable;
      description = "Enable node exporter";
    };

    podman.enable = mkOption {
      type = types.bool;
      default = presetCfg.enable;
      description = "Enable podman exporter";
    };
  };

  config = lib.mkIf (presetCfg.enable) {
    apps.exporters = {
      containers = {
        node = lib.mkIf presetCfg.node.enable {
          image = "quay.io/prometheus/node-exporter:v1.12.1@sha256:1b4e4438faca4dd7e001dd445d161a4a2091b0fededa84093b3a8dfeae1f1be0";
          extraOptions = [ "--pid=host" ];
          volumes = [
            "/:/host:ro,rslave"
            "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro"
          ];
          cmd = [
            "--path.rootfs=/host"
            "--collector.systemd"
            "--collector.textfile.directory=/host${textfileDir}"
          ];

          metrics = {
            job = "node";
            port = 9100;
          };
        };

        podman = lib.mkIf presetCfg.podman.enable {
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

    # node_filesystem only sees mounted datasets, so unmounted pools (harpy's
    # backups) report no usage. Publish zpool list numbers as textfile metrics.
    systemd.services.zpool-textfile = lib.mkIf (presetCfg.node.enable && supportsZfs) {
      serviceConfig.Type = "oneshot";
      serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];
      startAt = "*:0/5";
      path = [ pkgs.zfs ];
      script = ''
        dir=${textfileDir}
        mkdir -p "$dir"
        while read -r name size alloc free; do
          printf 'zpool_size_bytes{pool="%s"} %s\nzpool_allocated_bytes{pool="%s"} %s\nzpool_free_bytes{pool="%s"} %s\n' "$name" "$size" "$name" "$alloc" "$name" "$free"
        done < <(zpool list -Hp -o name,size,alloc,free) > "$dir/zpool.prom.tmp"
        mv "$dir/zpool.prom.tmp" "$dir/zpool.prom"
      '';
    };
  };
}
