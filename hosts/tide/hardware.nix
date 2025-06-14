{ pkgs, ... }: {
  boot = {
    initrd.systemd.enable = true;

    loader.efi.canTouchEfiVariables = true;

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    kernelPackages = pkgs.linuxPackages_6_12;

    kernelParams = [ "i915.modeset=0" "xe.force_probe=a7a1" ];

    blacklistedKernelModules = [ "i915" ];
  };

  hardware.enableRedistributableFirmware = true;

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
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings.allowDiscards = true;
                passwordFile = "/tmp/secret.key";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };

      storage0 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-FIKWOT_FN955_2TB_AA233920564";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };

      storage1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NG0R708350X";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };
    };

    zpool = {
      storage = {
        type = "zpool";
        mode = "mirror";
        mountpoint = "/storage";

        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          compression = "zstd";
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file:///root/storage.key";
          xattr = "sa";
        };

        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          services.type = "zfs_fs";
        };
      };
    };
  };
}
