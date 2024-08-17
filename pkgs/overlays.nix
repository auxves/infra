{ inputs, lib, ... }@args:
let
  isDirectory = name: type: type == "directory";
  packages = lib.filterAttrs isDirectory (builtins.readDir ./.);
in
rec {
  all = lib.composeManyExtensions [
    export
    inputs.fenix.overlays.default
  ];

  export = lib.composeManyExtensions [
    custom
  ];

  custom = final: prev: lib.mapAttrs
    (name: _: lib.callPackageWith (final // args // { inherit prev; }) ./${name} { })
    packages;
}
