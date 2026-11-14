{ ... }: {
  flake.modules.nixos.tide = { config, ... }: {
    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    services.sanoid = {
      enable = true;

      interval = "*:0/15";

      datasets = {
        storage = {
          useTemplate = [ "data" ];
          recursive = true;
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

      # Enable log scraping
      service.serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];
    };
  };

  flake.modules.nixos.harpy = { pkgs, ... }: {
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

      packages = with pkgs; [
        lzop
        mbuffer
      ];
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

            # dataset properties
            "sharenfs"
            "aclmode"
            "aclinherit"
          ];
        in
        ''
          zfs allow tide ${perms} backups/tide 
        '';
    };
  };
}
