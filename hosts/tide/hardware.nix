{ self, ... }: {
  imports = [
    self.inputs.lanzaboote.nixosModules.lanzaboote
    self.inputs.disko.nixosModules.disko
  ];

  boot = {
    bootspec.enabled = true;

    initrd.systemd.enable = true;

    loader.efi.canTouchEfiVariables = true;

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
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

      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
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
        mode = "stripe";
        mountpoint = "/storage";

        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          compression = "zstd";
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file:///tmp/storage.secret.key";
          xattr = "sa";
        };

        postCreateHook = ''
          zfs set keylocation=prompt $name;
        '';

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
