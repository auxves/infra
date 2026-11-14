{ inputs, ... }: {
  flake.services.vaultwarden.domain = "bitwarden.auxves.dev";

  flake.modules.nixos.tide = { config, ... }:
    let
      cfg = config.apps.vaultwarden;
    in
    {
      sops.secrets."vaultwarden/env" = { };

      apps.vaultwarden = {
        volumes = {
          data = { type = "zfs"; };
        };

        containers = {
          vaultwarden = {
            image = "ghcr.io/dani-garcia/vaultwarden:1.37.5@sha256:4fe17f415f90087377d37c755e0ea3cf189dcc6794e49cdd2a9adbb4937d9e1f";

            volumes = [
              "${cfg.volumes.data.path}:/data"
            ];

            environment = {
              DOMAIN = "https://${cfg.ingresses.app.domain}";

              SIGNUPS_ALLOWED = "false";

              SSO_ENABLED = "true";
              SSO_ONLY = "true";
              SSO_AUTHORITY = "https://${config.apps.pocket-id.ingresses.app.domain}";
              SSO_SCOPES = "email profile groups offline_access";
            };

            environmentFiles = [ config.sops.secrets."vaultwarden/env".path ];
          };
        };

        ingresses = {
          app = {
            domain = inputs.self.services.vaultwarden.domain;
            container = "vaultwarden";
            port = 80;
          };
        };
      };

      monitoring.checks = [{
        name = "vaultwarden";
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
