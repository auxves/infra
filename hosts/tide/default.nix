{ self, ... }:
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

  networking.hostId = "c2079ac5";

  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

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

  services.tailscale.enable = true;

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

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };
}
