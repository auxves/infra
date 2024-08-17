{ lib, config, pkgs, ... }:
let
  cfg = config.storage;

  pathType = with lib; types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        readOnly = true;
        default = config._module.args.name;
      };

      owner = mkOption {
        type = types.str;
        default = "root";
      };

      group = mkOption {
        type = types.str;
        default = "wheel";
      };

      mode = mkOption {
        type = types.str;
        default = "0770";
      };

      backend = mkOption {
        type = types.enum [ "zfs" "none" ];
        default = "zfs";
      };

      pool = mkOption {
        type = types.str;
        default = "storage";
      };

      path = mkOption {
        type = types.str;
        default = {
          zfs = "/${config.pool}/${config.name}";
          none = "/${config.name}";
        }.${config.backend};
      };
    };
  });

  mkRule = _: path: "d ${path.path} ${path.mode} ${path.owner} ${path.group} -";

  mkDataset = _: path: lib.optionalAttrs (path.backend == "zfs") {
    ${path.pool}.datasets.${path.name}.type = "zfs_fs";
  };
in
{
  options.storage = with lib; {
    enable = mkEnableOption "Enable storage system";

    paths = mkOption {
      type = types.attrsOf pathType;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = lib.mapAttrsToList mkRule cfg.paths;

    disko.devices.zpool = lib.mkMerge (lib.mapAttrsToList mkDataset cfg.paths);

    system.activationScripts.sync-zfs-datasets.text =
      let
        pools = config.disko.devices.zpool;

        datasets = builtins.concatMap
          (pool: lib.mapAttrsToList (_: dataset: dataset._name) pool.datasets)
          (builtins.attrValues pools);

        commands = builtins.map (path: "${pkgs.zfs}/bin/zfs create -p ${path}") datasets;
      in
      builtins.concatStringsSep "\n" commands;
  };
}
