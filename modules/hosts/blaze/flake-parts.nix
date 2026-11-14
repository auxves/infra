{ inputs, ... }: {
  flake.darwinConfigurations = inputs.self.lib.mkDarwin "aarch64-darwin" "blaze";

  perSystem = { pkgs, lib, ... }: {
    checks.system-blaze =
      let
        drv = inputs.self.darwinConfigurations.blaze.config.system.build.toplevel;
        drvPath = builtins.unsafeDiscardStringContext drv.drvPath;
      in
      pkgs.runCommand "system-blaze-evaluates" { } ''
        echo ${drvPath} > $out
      '';
  };
}
