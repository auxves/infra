{ config, pkgs, ... }: {
  systemd.services.zfs-canary = {
    after = [ "zfs-mount.service" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.TimeoutStartSec = 600;
    serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];
    path = with pkgs; [
      coreutils
      findutils
      python3
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

      find "$root" -name '*.tmp' -type f -delete

      remove_tmp() {
        find "$root" -name '*.tmp' -type f -delete
      }
      trap remove_tmp EXIT

      python3 - "$root" "$seed" <<'PYEOF' || fail generate "python generation failed"
      import hashlib
      import os
      import sys

      root = sys.argv[1]
      seed = sys.argv[2]
      files = [
          ("data/a.bin", 4194304),
          ("data/b.bin", 4194304),
          ("data/nested/c.bin", 2097152),
          ("data/nested/deep/d.bin", 2097152),
          ("logs/e.txt", 1048576),
          ("f.bin", 1048576),
          ("g.bin", 1048576),
          ("data/nested/h.bin", 524288),
          ("meta/i.txt", 524288),
      ]

      for rel, size in files:
          block = hashlib.sha256(f"{seed}:{rel}".encode()).hexdigest()
          parts = []
          remaining = size
          while remaining > 0:
              parts.append(block.encode())
              block = hashlib.sha256(block.encode()).hexdigest()
              remaining -= 64
          dest = os.path.join(root, rel)
          os.makedirs(os.path.dirname(dest), exist_ok=True)
          tmp = dest + ".tmp"
          with open(tmp, "wb") as handle:
              handle.write(b"".join(parts)[:size])
          os.rename(tmp, dest)
      PYEOF

      (
        cd "$root"
        find . -type f ! -name manifest.sha256 ! -name '*.tmp' -print0 | sort -z | xargs -0 sha256sum > manifest.sha256.tmp
        mv manifest.sha256.tmp manifest.sha256
      ) || fail generate "manifest build failed"

      describe
      if [ "$files" -ne 9 ]; then
        fail generate "manifest lists $files files, expected 9"
      fi

      zfs set auxves:canary-seed-hash="$seedhash" "$dataset" || fail marker "could not set the seed marker"

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
