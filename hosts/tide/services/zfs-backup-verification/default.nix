{ config, pkgs, ... }: {
  systemd.services.zfs-canary = {
    after = [ "zfs-mount.service" ];
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

      seed=auxves-zfs-canary-v1
      seedhash=$(printf '%s' "$seed" | sha256sum | cut -d' ' -f1)

      fail() {
        echo "zfs-canary: FAILED stage=$1 detail=$2" >&2
        exit 1
      }

      describe() {
        files=$(wc -l < "$root/manifest.sha256")
        hash=$(sha256sum "$root/manifest.sha256" | cut -d' ' -f1)
      }

      created=0
      if zfs list "$dataset" >/dev/null 2>&1; then
        marker=$(zfs get -Hp -o value auxves:canary-seed-hash "$dataset" || true)
        if [ "$marker" = "$seedhash" ] && [ -f "$root/manifest.sha256" ]; then
          describe
          echo "zfs-canary: seed match files=$files manifest_sha256=$hash"
          exit 0
        fi
      else
        zfs create "$dataset" || fail create "zfs create $dataset failed"
        created=1
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
      ) || fail generate "manifest build failed"

      zfs set auxves:canary-seed-hash="$seedhash" "$dataset" || fail marker "could not set the seed marker"

      describe
      if [ "$files" -ne 9 ]; then
        fail generate "manifest lists $files files, expected 9"
      fi

      if [ "$created" = 1 ]; then
        echo "zfs-canary: created dataset=$dataset files=$files manifest_sha256=$hash"
      else
        echo "zfs-canary: regenerated files=$files manifest_sha256=$hash"
      fi
    '';
  };

  systemd.services.zfs-drill = {
    requires = [ "zfs-canary.service" ];
    after = [ "zfs-canary.service" ];
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
      key=${config.sops.secrets."syncoid/ssh".path}

      cleanup() {
        zfs umount "$scratch" >/dev/null 2>&1 || true
        zfs destroy -r "$scratch" >/dev/null 2>&1 || true
      }

      fail() {
        echo "zfs-drill: FAILED stage=$1 detail=$2" >&2
        cleanup
        exit 1
      }

      if zfs list "$scratch" >/dev/null 2>&1; then
        zfs umount "$scratch" >/dev/null 2>&1 || true
        zfs destroy -r "$scratch" || fail preclean "could not destroy leftover $scratch"
      fi

      snapshot=$(ssh -i "$key" -o BatchMode=yes -o StrictHostKeyChecking=accept-new tide@harpy "zfs list -Hp -t snapshot -o name -s creation -d 1 backups/tide/canary" | tail -n 1)
      if [ -z "$snapshot" ]; then
        fail snapshot-list "no canary snapshot found on harpy"
      fi

      if ! ssh -i "$key" -o BatchMode=yes -o StrictHostKeyChecking=accept-new tide@harpy "zfs send -w $snapshot" | zfs receive -o syncoid:sync=false -u "$scratch"; then
        fail receive "zfs receive failed for $snapshot"
      fi

      if ! zfs load-key -L file:///root/storage.key "$scratch"; then
        fail load-key "could not load the key for $scratch"
      fi

      if ! zfs mount "$scratch"; then
        fail mount "could not mount $scratch"
      fi

      if [ ! -f "$root/manifest.sha256" ]; then
        fail manifest "manifest.sha256 missing in the received snapshot"
      fi

      total=$(wc -l < "$root/manifest.sha256")
      verified=$(cd "$root" && sha256sum -c manifest.sha256 | grep -c ': OK' || true)

      if [ "$verified" -ne "$total" ]; then
        fail verify "verified $verified of $total files"
      fi

      echo "zfs-drill: success snapshot=$snapshot verified_files=$verified"
      cleanup
    '';
  };
}
