{ self, config, pkgs, ... }: {
  imports = [
    self.inputs.sops.nixosModules.sops
    ./hardware.nix
    ./services
  ];

  presets = {
    home.enable = true;
    containers.enable = true;
    emulation.enable = true;
    gitops.enable = true;

    builders = {
      volunteer = true;
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUNWcC8vMlNYcHY1bWdQT0dxZ2NSUnVYMXRrS1VQN2dRNVk2SWRKb0YxTHAgcm9vdEB0aWRlCg==";
    };
  };

  networking.hostId = "c2079ac5";

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    interfaces."podman+".allowedUDPPorts = [
      5353 # mDNS
    ];
  };

  systemd.network.enable = true;
  networking.useNetworkd = true;

  services.tailscale.enable = true;

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "socket options" = "IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072";
        "getwd cache" = "true";
        "strict sync" = "no";
        "sync always" = "no";
        "use sendfile" = "true";
        "deadtime" = "30";
        "min receivefile size" = "16384";
      };

      storage = {
        path = "/storage";
        browseable = true;
        "read only" = false;
      };
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  services.sanoid = {
    enable = true;

    interval = "*:0/15";

    datasets = {
      "storage" = {
        useTemplate = [ "data" ];
        recursive = true;
      };

      "storage/media/movies".autosnap = false;
      "storage/media/shows".autosnap = false;
    };

    templates.data = {
      autosnap = true;
      autoprune = true;
      hourly = 12;
      daily = 6;
      weekly = 3;
      monthly = 2;
    };
  };

  sops.secrets."syncoid/ssh" = {
    owner = "syncoid";
    group = "syncoid";
    mode = "0400";
  };

  services.syncoid = {
    enable = true;
    interval = "daily";
    sshKey = config.sops.secrets."syncoid/ssh".path;

    commands = {
      storage = {
        target = "tide@harpy:backups/tide";
        recursive = true;
        sendOptions = "w p";
        extraArgs = [ "--exclude-snaps=autosnap" "--no-stream" ];
      };
    };

    # Enable log scraping
    service.serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];
  };

  systemd.services.zfs-canary = {
    serviceConfig.Type = "oneshot";
    serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];
    startAt = "monthly";
    path = with pkgs; [
      coreutils
      findutils
      zfs
    ];
    script = ''
      dataset=storage/canary
      root=/storage/canary
      dir=/var/lib/node-exporter/textfile

      zfs list "$dataset" >/dev/null 2>&1 || zfs create "$dataset"

      seed=auxves-zfs-canary-v1
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

      hash=$(sha256sum "$root/manifest.sha256" | cut -d' ' -f1)
      count=$(wc -l < "$root/manifest.sha256")
      mkdir -p "$dir"
      printf 'zfs_canary_manifest_info{sha256="%s"} 1\nzfs_canary_files %s\nzfs_canary_last_generated_timestamp_seconds %s\n' "$hash" "$count" "$(date +%s)" > "$dir/zfs-canary.prom.tmp"
      mv "$dir/zfs-canary.prom.tmp" "$dir/zfs-canary.prom"
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

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Host connectivity checks due to history of firewall rule issues
  monitoring.checks = [
    {
      name = "tide-ipv4";
      group = "hosts";
      url = "tcp://v4.tide.auxves.dev:443";
      interval = "1m";
      alerts = [{ type = "discord"; }];
      conditions = [
        "[CONNECTED] == true"
      ];
    }
    {
      name = "tide-ipv6";
      group = "hosts";
      url = "tcp://v6.tide.auxves.dev:443";
      interval = "1m";
      alerts = [{ type = "discord"; }];
      conditions = [
        "[CONNECTED] == true"
      ];
    }
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  meta.addresses = {
    public.v4 = "162.196.81.91";
    public.v6 = "2600:1700:78c0:130f:2e0:4cff:fe88:9afa";
    internal.v4 = "100.126.20.86";
    internal.v6 = "fd7a:115c:a1e0::3901:1456";
  };

  system.stateVersion = "23.05";
}
