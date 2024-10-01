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

      acls = mkOption {
        type = types.listOf types.str;
        default = [ "g:wheel:rwx" ];
      };

      backend = mkOption {
        type = types.enum [ "zfs" "local" ];
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
          local = "/${config.name}";
        }.${config.backend};
      };
    };
  });

  mkRule = _: path:
    let
      acls = path.acls ++ map (a: "d:${a}") path.acls;
    in
    lib.optionalString (path.backend == "local") ''
      d ${path.path} 0700 root root -
    '' + ''
      A ${path.path} - - - - ${builtins.concatStringsSep "," acls}
    '';

  mkDataset = _: path: lib.optionalAttrs (path.backend == "zfs") {
    ${path.pool}.datasets.${path.name}.type = "zfs_fs";
  };
in
{
  options.storage = with lib; {
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
