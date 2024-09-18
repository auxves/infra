{ self, config, pkgs, ... }:
{
  imports = [
    self.inputs.sops.nixosModules.sops
    ./hardware.nix
    ./services
  ];

  presets = {
    home.enable = true;
  };

  storage = {
    enable = true;
    zfs.health.enable = true;
    zfs.health.webhook = "https://uptime.x.auxves.dev/api/push/LieheAkPr6";
  };

  networking.hostId = "c2079ac5";

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 5353 ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;

    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };

    defaultNetwork.settings = {
      dns_enabled = true;
      ipv6_enabled = true;

      subnets = [
        { gateway = "10.88.0.1"; subnet = "10.88.0.0/16"; }
        { gateway = "fd80::1"; subnet = "fd80::/64"; }
      ];
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:auxves/infra";
    dates = "hourly";
  };

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  services.sanoid = {
    enable = true;
    package = pkgs.sanoid-unstable;

    interval = "*:0/15";

    datasets = {
      "storage" = {
        useTemplate = [ "data" ];
        recursive = "zfs";
      };
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
    package = pkgs.sanoid-unstable;
    sshKey = config.sops.secrets."syncoid/ssh".path;

    commands = {
      storage = {
        target = "tide@harpy:backups/tide";
        recursive = true;
        sendOptions = "w p";
        extraArgs = [ "--exclude-snaps=autosnap" ];
      };
    };
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  systemd.services.zpool-health-check =
    let
      script = pkgs.writeShellApplication {
        name = "check-status";
        runtimeInputs = with pkgs; [ zfs curl ];
        text = ''
          if [ "$(zpool status -x)" = "all pools are healthy" ]; then
            STATUS=up
            MESSAGE="All pools are healthy"
          else
            STATUS=down
            MESSAGE="One or more pools are degraded"
          fi

          curl --get \
            --data-urlencode "status=$STATUS" \
            --data-urlencode "msg=$MESSAGE" \
            https://uptime.x.auxves.dev/api/push/LieheAkPr6
        '';
      };
    in
    {
      description = "Health check for ZFS pools which reports to Uptime Kuma";
      after = [ "podman-uptime-kuma.service" ];
      startAt = "*:*:00";

      serviceConfig = {
        User = "nobody";
        Group = "nobody";

        ExecStart = "${script}/bin/check-status";
      };
    };
}
