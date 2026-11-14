{ ... }: {
  flake.modules.nixos.tide = { ... }: {
    presets.apps = {
      alloy.enable = true;
      exporters.enable = true;
    };
  }
  ;
}
