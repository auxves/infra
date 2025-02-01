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
    containers.enable = true;
  };

  networking.hostId = "c2079ac5";

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    interfaces."podman+".allowedUDPPorts = [ 5353 ];
  };

  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/auxves/infra";
    }];
  };

  services.tailscale.enable = true;

  services.samba = {
    enable = true;
    settings = {
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
    health.enable = true;
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
