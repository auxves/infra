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
        image = "ghcr.io/dani-garcia/vaultwarden:1.36.0@sha256:d626d04934cd1192ad8ced1adb975099fca78cec33ab467d2d3c923cde7f3b0c";

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
