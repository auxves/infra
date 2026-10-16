{ ... }: {
  sops.secrets."alloy/env" = {
    sopsFile = ../../../secrets.yaml;
  };

  apps.alloy = {
    presets.alloy.enable = true;
  };

  apps.exporters = {
    presets.exporters.enable = true;
  };
}
