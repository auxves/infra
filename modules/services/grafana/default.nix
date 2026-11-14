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
            image = "grafana/grafana:13.3.1@sha256:0615ec4fbd4072004b7d86b46ded63013a74b7d6eb1119273dd89e8fa25c13cf";
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
