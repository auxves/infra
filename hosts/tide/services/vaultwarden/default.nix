{ config, ... }:
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
        image = "ghcr.io/dani-garcia/vaultwarden:1.35.8@sha256:c4f6056fe0c288a052a223cecd263a90d1dda1a0177bb5b054a363a6c7b211d9";

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
        domain = "bitwarden.auxves.dev";
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
}
