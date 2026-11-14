{ ... }: {
  perSystem = { pkgs, lib, ... }: {
    checks = lib.filterAttrs
      (_: lib.meta.availableOn pkgs.stdenv.hostPlatform)
      pkgs.auxves.checks;
  };
}
