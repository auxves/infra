{ ... }: {
  flake.modules.nixos.tide = { config, ... }:
    let
      cfg = config.apps.grafana;
    in
    {
      apps.grafana = {
        volumes = {
          grafana = { type = "zfs"; };
        };

        containers = {
          grafana = {
            image = "grafana/grafana:13.3.2@sha256:81556409ba48b2b922e0adb69a2511337d8ba7578f11962eefa6149a2d815101";
            user = "root:root";

            volumes = [
              "${cfg.volumes.grafana.path}:/var/lib/grafana"
            ];

            environment = {
              HOSTNAME = cfg.ingresses.app.domain;
              GF_SERVER_ROOT_URL = "https://${cfg.ingresses.app.domain}";
              GF_ANALYTICS_REPORTING_ENABLED = "false";
            };
          };
        };

        ingresses = {
          app = {
            domain = "grafana.auxves.dev";
            container = "grafana";
            port = 3000;
          };
        };
      };

      monitoring.checks = [{
        name = "grafana";
        group = "services";
        url = "https://${cfg.ingresses.app.domain}";
        interval = "1m";
        alerts = [{ type = "discord"; }];
        conditions = [
          "[STATUS] == 200"
        ];
      }];
    };
}
