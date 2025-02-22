{ ... }: {
  apps.alloy = {
    presets.alloy.enable = true;
  };

  apps.exporters = {
    presets.exporters.enable = true;
  };
}
