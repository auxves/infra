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
}
