{ self, config, pkgs, ... }:
{
  imports = [
    self.inputs.comin.nixosModules.comin
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

  networking.firewall.interfaces.podman0.allowedTCPPorts = [
    5580 # Matter server
  ];

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

  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/auxves/infra";
    }];
  };

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  services.samba = {
    enable = true;
    securityType = "user";
    shares = {
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
}
