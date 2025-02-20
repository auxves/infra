{ lib, config, host, ... }:
let
  federationHosts = lib.filterHosts (h: h != host && h.cfg ? apps.prometheus.ingress.domain);
  federationTargets = map (h: h.cfg.apps.prometheus.ingress.domain) federationHosts;
in
{
  apps.prometheus = {
    presets.prometheus.enable = true;

    volumes = {
      prometheus = { type = "zfs"; };
    };

    presets.prometheus.configs = [
      {
        job_name = "comin";
        static_configs = [{
          targets = [ "host.containers.internal:4243" ];
          labels.node = config.networking.hostName;
        }];
      }
      {
        job_name = "federation";
        honor_labels = true;
        metrics_path = "/federate";
        scheme = "https";

        params."match[]" = [ ''{job=~".+"}'' ];

        static_configs = [{ targets = federationTargets; }];
      }
    ];
  };

  apps.exporters = {
    presets.exporters.enable = true;
  };
}
