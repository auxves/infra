self@{ inputs, lib, ... }:
rec {
  all = lib.composeManyExtensions [
    overlayTools
    pythonPackages
    nuModules
    scripts
    patches
    tools
    inputs.fenix.overlays.default
  ];

  overlayTools = final: prev: {
    inherit self lib;
  };

  scripts = import ./scripts/overlay.nix;
  pythonPackages = import ./pythonPackages/overlay.nix;
  nuModules = import ./nuModules/overlay.nix;
  patches = import ./patches/overlay.nix;
  tools = import ./tools/overlay.nix;

  unstable = final: _: {
    unstable = import inputs.unstable {
      inherit (final) config system overlays;
    };
  };
}
