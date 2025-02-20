{ config, ... }: {
  apps.prometheus = {
    presets.prometheus.enable = true;

    volumes = {
      prometheus = { type = "ephemeral"; };
    };

    presets.prometheus.configs = [
      {
        job_name = "comin";
        static_configs = [{
          targets = [ "host.containers.internal:4243" ];
          labels.node = config.networking.hostName;
        }];
      }
    ];
  };

  apps.exporters = {
    presets.exporters.enable = true;
  };
}
