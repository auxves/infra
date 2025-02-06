{ inputs, lib, ... }@args:
let
  isDirectory = name: type: type == "directory";
  packages = lib.filterAttrs isDirectory (builtins.readDir ./.);
in
rec {
  all = lib.composeManyExtensions [
    default
    inputs.fenix.overlays.default
  ];

  default = final: prev: lib.mapAttrs
    (name: _: lib.callPackageWith (final // args // { inherit prev; self = args; }) ./${name} { })
    packages;

  unstable = final: _: {
    unstable = import inputs.unstable {
      inherit (final) system overlays;
    };
  };
}
