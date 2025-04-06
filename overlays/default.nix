self@{ inputs, ... }:
rec {
  all = inputs.nixpkgs.lib.composeManyExtensions [
    overlayTools
    pythonPackages
    nuModules
    scripts
    packages
    patches
    tools
    inputs.fenix.overlays.default
  ];

  lib = import ./lib/overlay.nix self;
  scripts = import ./scripts/overlay.nix;
  packages = import ./packages/overlay.nix;
  pythonPackages = import ./pythonPackages/overlay.nix;
  nuModules = import ./nuModules/overlay.nix;
  patches = import ./patches/overlay.nix;
  tools = import ./tools/overlay.nix;

  overlayTools = final: prev: {
    inherit self;
    lib = prev.lib.extend lib;
  };

  unstable = final: _: {
    unstable = import inputs.unstable {
      inherit (final) config system overlays;
    };
  };
}
