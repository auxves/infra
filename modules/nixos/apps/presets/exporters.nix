{ config, lib, pkgs, ... }:
let
  presetCfg = config.presets.apps.exporters;

  textfileDir = "/var/lib/node-exporter/textfile";

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
        {
          while read -r name size alloc free; do
            printf 'zpool_size_bytes{pool="%s"} %s\nzpool_allocated_bytes{pool="%s"} %s\nzpool_free_bytes{pool="%s"} %s\n' "$name" "$size" "$name" "$alloc" "$name" "$free"
          done < <(zpool list -Hp -o name,size,alloc,free)

          while read -r pool; do
            status=$(zpool status -p "$pool" || true)
            scan=$(printf '%s\n' "$status" | grep '^  scan:' || true)
            state=none
            epoch=0
            case "$scan" in
              *"scrub in progress"*)
                state=in-progress
                epoch=$(date -d "''${scan##* since }" +%s 2>/dev/null) || epoch=0
                ;;
              *"scrub repaired"*)
                state=finished
                epoch=$(date -d "''${scan##* on }" +%s 2>/dev/null) || epoch=0
                ;;
              *"scrub canceled"*)
                state=canceled
                epoch=$(date -d "''${scan##* on }" +%s 2>/dev/null) || epoch=0
                ;;
            esac
            printf 'zpool_scrub_state{pool="%s",state="%s"} 1\n' "$pool" "$state"
            if [ "$epoch" -gt 0 ]; then
              printf 'zpool_scrub_last_timestamp_seconds{pool="%s"} %s\n' "$pool" "$epoch"
            fi
            printf '%s\n' "$status" | awk -v pool="$pool" '$1 == pool && NF >= 5 { printf "zpool_read_errors{pool=\"%s\"} %s\nzpool_write_errors{pool=\"%s\"} %s\nzpool_checksum_errors{pool=\"%s\"} %s\n", pool, $3, pool, $4, pool, $5; exit }'
          done < <(zpool list -Hp -o name)
        } > "$dir/zpool.prom.tmp"
        mv "$dir/zpool.prom.tmp" "$dir/zpool.prom"
      '';
    };

    systemd.services.zfs-snapshot-textfile = lib.mkIf (presetCfg.node.enable && supportsZfs) {
      serviceConfig.Type = "oneshot";
      serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];
      startAt = "*:0/5";
      path = [ pkgs.zfs ];
      script = ''
        dir=${textfileDir}
        mkdir -p "$dir"
        {
          while read -r dataset; do
            line=$(zfs list -Hp -d 1 -t snapshot -o name,guid,creation -s creation "$dataset" | awk '$1 !~ /@autosnap_/ { newest = $0 } END { print newest }')
            if [ -n "$line" ]; then
              guid=$(printf '%s' "$line" | awk '{ print $2 }')
              creation=$(printf '%s' "$line" | awk '{ print $3 }')
              printf 'zfs_snapshot_newest_creation_seconds{dataset="%s",guid="%s"} %s\n' "$dataset" "$guid" "$creation"
            fi
          done < <(zfs list -Hp -t filesystem,volume -o name)
        } > "$dir/zfs-snapshots.prom.tmp"
        mv "$dir/zfs-snapshots.prom.tmp" "$dir/zfs-snapshots.prom"
      '';
    };
  };
}
