{ ... }: {
  flake.modules.nixos.harpy = { ... }: {
    presets.apps = {
      alloy.enable = true;
      exporters.enable = true;
    };
  }
  ;
}
