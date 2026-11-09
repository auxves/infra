{ config, pkgs, ... }: {
  systemd.services.zfs-canary = {
    after = [ "zfs-mount.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];
    path = with pkgs; [
      coreutils
      findutils
      zfs
    ];
    script = ''
      dataset=storage/canary
      root=/storage/canary
      dir=/var/lib/node-exporter/textfile

      seed=auxves-zfs-canary-v1
      seedhash=$(printf '%s' "$seed" | sha256sum | cut -d' ' -f1)

      publish() {
        hash=$(sha256sum "$root/manifest.sha256" | cut -d' ' -f1)
        count=$(wc -l < "$root/manifest.sha256")
        mkdir -p "$dir"
        printf 'zfs_canary_manifest_info{sha256="%s"} 1\nzfs_canary_files %s\nzfs_canary_last_generated_timestamp_seconds %s\n' "$hash" "$count" "$1" > "$dir/zfs-canary.prom.tmp"
        mv "$dir/zfs-canary.prom.tmp" "$dir/zfs-canary.prom"
      }

      if zfs list "$dataset" >/dev/null 2>&1; then
        marker=$(zfs get -Hp -o value auxves:canary-seed-hash "$dataset" || true)
        if [ "$marker" = "$seedhash" ] && [ -f "$root/manifest.sha256" ]; then
          publish "$(stat -c %Y "$root/manifest.sha256")"
          exit 0
        fi
      else
        zfs create "$dataset"
      fi

      gen() {
        rel="$1"
        size="$2"
        mkdir -p "$root/$(dirname "$rel")"
        block=$(printf '%s' "$seed:$rel" | sha256sum | cut -d' ' -f1)
        : > "$root/$rel.tmp"
        remaining=$size
        while [ "$remaining" -gt 0 ]; do
          printf '%s' "$block" >> "$root/$rel.tmp"
          block=$(printf '%s' "$block" | sha256sum | cut -d' ' -f1)
          remaining=$((remaining - 64))
        done
        head -c "$size" "$root/$rel.tmp" > "$root/$rel"
        rm "$root/$rel.tmp"
      }

      gen data/a.bin 4194304
      gen data/b.bin 4194304
      gen data/nested/c.bin 2097152
      gen data/nested/deep/d.bin 2097152
      gen logs/e.txt 1048576
      gen f.bin 1048576
      gen g.bin 1048576
      gen data/nested/h.bin 524288
      gen meta/i.txt 524288

      (
        cd "$root"
        find . -type f ! -name manifest.sha256 -print0 | sort -z | xargs -0 sha256sum > manifest.sha256.tmp
        mv manifest.sha256.tmp manifest.sha256
      )

      zfs set auxves:canary-seed-hash="$seedhash" "$dataset"
      publish "$(date +%s)"
    '';
  };

  systemd.services.zfs-drill = {
    serviceConfig.Type = "oneshot";
    serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];
    startAt = "monthly";
    path = with pkgs; [
      coreutils
      gnugrep
      openssh
      zfs
    ];
    script = ''
      scratch=storage/drill
      root=/storage/drill
      dir=/var/lib/node-exporter/textfile
      key=${config.sops.secrets."syncoid/ssh".path}
      mkdir -p "$dir"

      cleanup() {
        zfs umount "$scratch" >/dev/null 2>&1 || true
        zfs destroy -r "$scratch" >/dev/null 2>&1 || true
      }

      record() {
        printf 'zfs_drill_last_run_timestamp_seconds %s\nzfs_drill_success %s\nzfs_drill_verified_files %s\n' "$(date +%s)" "$1" "$2" > "$dir/zfs-drill.prom.tmp"
        mv "$dir/zfs-drill.prom.tmp" "$dir/zfs-drill.prom"
      }

      fail() {
        record 0 "$1"
        cleanup
        exit 1
      }

      cleanup

      snapshot=$(ssh -i "$key" -o BatchMode=yes -o StrictHostKeyChecking=accept-new tide@harpy "zfs list -Hp -t snapshot -o name -s creation -d 1 backups/tide/canary" | tail -n 1)
      if [ -z "$snapshot" ]; then
        fail 0
      fi

      if ! ssh -i "$key" -o BatchMode=yes -o StrictHostKeyChecking=accept-new tide@harpy "zfs send -w $snapshot" | zfs receive -u "$scratch"; then
        fail 0
      fi

      if ! zfs load-key -L file:///root/storage.key "$scratch"; then
        fail 0
      fi

      if ! zfs mount "$scratch"; then
        fail 0
      fi

      if [ ! -f "$root/manifest.sha256" ]; then
        fail 0
      fi

      total=$(wc -l < "$root/manifest.sha256")
      verified=$(cd "$root" && sha256sum -c manifest.sha256 | grep -c ': OK' || true)

      if [ "$verified" -eq "$total" ]; then
        printf 'zfs_drill_last_success_timestamp_seconds %s\n' "$(date +%s)" > "$dir/zfs-drill-success.prom.tmp"
        mv "$dir/zfs-drill-success.prom.tmp" "$dir/zfs-drill-success.prom"
        record 1 "$verified"
        cleanup
        exit 0
      fi

      fail "$verified"
    '';
  };
}
