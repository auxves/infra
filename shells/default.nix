{ inputs, lib, ... }@args: system:
let
  pkgs = lib.pkgsFor system;

  isDirectory = name: type: type == "directory";
  packages = lib.filterAttrs isDirectory (builtins.readDir ./.);
in
lib.mapAttrs
  (name: _: lib.callPackageWith (pkgs // args) ./${name} { })
  packages
