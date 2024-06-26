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

  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/auxves/infra";
    }];
  };

  services.tailscale.enable = true;

  services.nfs.server.enable = true;

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune.enable = true;

    defaultNetwork.settings = {
      dns_enabled = true;
      ipv6_enabled = true;
    };
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
