{ pkgs, ... }: {
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  users.groups.syncoid = { };

  users.users.tide = {
    isNormalUser = true;
    group = "syncoid";
    home = "/home/tide";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXrz2geCofvG1mAsSrYw+JG4XVTdLgNP2yuHVqXCiRy syncoid@tide" ];
  };

  systemd.services.allow-remote-users = {
    after = [ "zfs.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.zfs ];

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
        zfs allow tide ${perms} backups/tide 
      '';
  };

}
