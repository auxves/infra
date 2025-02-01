{ lib, config, pkgs, ... }:
let
  volumes = builtins.concatLists (lib.mapAttrsToList
    (_: app: builtins.attrValues app.volumes)
    config.apps);

  mkRules = volume:
    let
      acls = [
        "g:wheel:rwx"
        "d:wheel:rwx"
        "u:services:rwx"
        "g:services:rwx"
      ];
    in
    lib.optionalString (volume.type == "ephemeral") ''
      d ${volume.path} 0770 root root -
    '' + ''
      a ${volume.path} - - - - ${builtins.concatStringsSep "," acls}
    '';
in
{
  config = lib.mkIf (config.apps != { }) {
    systemd.tmpfiles.rules = builtins.map mkRules volumes;

    system.activationScripts.ensure-zfs-datasets.text =
      let
        commands = builtins.map (volume: "${pkgs.zfs}/bin/zfs create -p ${lib.removePrefix "/" volume.path}") volumes;
      in
      builtins.concatStringsSep "\n" commands;
  };
}
