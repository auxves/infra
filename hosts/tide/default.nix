{ self, ... }:
{
  imports = [
    ./hardware.nix
    self.inputs.comin.nixosModules.comin
  ];

  modules = {
    home.enable = true;
  };

  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/auxves/infra";
    }];
  };

  services.nfs.server.enable = true;

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  virtualisation = {
    containers.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;

      defaultNetwork.settings = {
        dns_enabled = true;
        ipv6_enabled = true;
      };
    };
  };
}
