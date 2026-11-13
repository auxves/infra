{ ... }: {
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.callPackage ../shells/default { };
  };
}
