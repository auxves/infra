{ inputs, lib, ... }@args:
let
  isDirectory = name: type: type == "directory";
  packages' = lib.filterAttrs isDirectory (builtins.readDir ./derivations/pkgs);
  tools' = lib.filterAttrs isDirectory (builtins.readDir ./derivations/tools);
in
rec {
  all = lib.composeManyExtensions [
    packages
    tools
    patches
    inputs.fenix.overlays.default
  ];

  patches = final: prev: {
    podman = prev.podman.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ ./derivations/patches/podman/rfc3339nano-logs.patch ];
      });
  };

  packages = final: prev: lib.mapAttrs
    (name: _: lib.callPackageWith (final // args // { inherit prev; self = args; }) ./derivations/pkgs/${name} { })
    packages';

  tools = final: prev: lib.mapAttrs
    (name: _: lib.callPackageWith (final // args // { inherit prev; self = args; }) ./derivations/tools/${name} { })
    tools';

  unstable = final: _: {
    unstable = import inputs.unstable {
      inherit (final) system overlays;
    };
  };
}
