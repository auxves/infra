{ self, config, pkgs, ... }:
{
  imports = [
    self.inputs.comin.nixosModules.comin
    ./hardware.nix
    ./services
  ];

  modules = {
    home.enable = true;
  };

  networking.hostId = "c2079ac5";

  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune.enable = true;

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

  system.activationScripts.sync-zfs-datasets.text =
    let
      pools = config.disko.devices.zpool;

      datasets = builtins.concatMap
        (pool:
          builtins.map (path: "${pool}/${path}")
            (builtins.filter (path: path != "__root")
              (builtins.attrNames pools.${pool}.datasets)))
        (builtins.attrNames pools);

      commands = builtins.map (path: "${pkgs.zfs}/bin/zfs create -p ${path}") datasets;
    in
    builtins.concatStringsSep "\n" commands;
}
