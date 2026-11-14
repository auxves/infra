{ inputs, ... }: {
  flake.services.pocket-id.domain = "id.auxves.dev";

  flake.modules.nixos.tide = { config, ... }:
    let
      cfg = config.apps.pocket-id;
    in
    {
      sops.secrets."pocket-id/env" = { };

      apps.pocket-id = {
        volumes = {
          data = { type = "zfs"; };
        };

        containers = {
          pocket-id = {
            image = "ghcr.io/pocket-id/pocket-id:v2.19.2@sha256:3ee23895d6a3adb5dd5de801a4fd31fc31b960e6dfbea9b5200e33cf477695eb";

            volumes = [
              "${cfg.volumes.data.path}:/app/data"
            ];

            environment = {
              APP_URL = "https://${cfg.ingresses.app.domain}";
              TRUST_PROXY = "true";
              PUID = "0";
              PGID = "0";
            };

            environmentFiles = [ config.sops.secrets."pocket-id/env".path ];
          };
        };

        ingresses = {
          app = {
            type = "public";
            domain = inputs.self.services.pocket-id.domain;
            container = "pocket-id";
            port = 1411;
          };
        };
      };

      monitoring.checks = [{
        name = "pocket-id";
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
