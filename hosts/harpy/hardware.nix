{ self, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.inputs.disko.nixosModules.disko
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 5;
    loader.efi.canTouchEfiVariables = true;

    supportedFilesystems = [ "zfs" ];

    zfs = {
      forceImportRoot = false;
      extraPools = [ "backups" ];
      requestEncryptionCredentials = [ ];
    };

    extraModprobeConfig = ''
      options zfs zfs_arc_max=2147483648
    '';
  };

  disko.devices = {
    disk = {
      root = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      storage = {
        type = "disk";
        device = "/dev/sdb";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "backups";
              };
            };
          };
        };
      };
    };

    zpool = {
      backups = {
        type = "zpool";

        options = {
          ashift = "12";
          autotrim = "on";
        };
      };
    };
  };
}
