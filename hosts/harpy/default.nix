{ self, pkgs, ... }: {
  imports = [
    self.inputs.comin.nixosModules.comin
    ./hardware.nix
  ];

  networking.hostId = "c2079aa6";

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

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

  users.users.tide = {
    isNormalUser = true;
    group = "syncoid";
    home = "/home/tide";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXrz2geCofvG1mAsSrYw+JG4XVTdLgNP2yuHVqXCiRy syncoid@tide"
    ];
  };

  users.groups.syncoid = { };

  systemd.services.allow-remote-users = {
    after = [ "zfs.target" ];
    wantedBy = [ "multi-user.target" ];

    script =
      let
        perms = builtins.concatStringsSep "," [
          "change-key"
          "compression"
          "create"
          "mount"
          "mountpoint"
          "receive"
          "rollback"
          "destroy"
        ];
      in
      ''
        ${pkgs.zfs}/bin/zfs allow tide ${perms} backups/tide 
      '';
  };
}
