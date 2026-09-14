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
        image = "ghcr.io/dani-garcia/vaultwarden:1.37.3@sha256:1587c45feaa479f1f5e8af3b00eded36bff77bcf1880cf8dbf0541706dd470e0";

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
