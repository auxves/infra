{ config, ... }: {
  imports = [
    ./hardware.nix
    ./services
  ];

  presets = {
    home.enable = true;
    containers.enable = true;
    emulation.enable = true;

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
    interfaces."podman+".allowedTCPPorts = [
      4243 # comin
    ];
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
  };

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
}
