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
        image = "vaultwarden/server:testing-alpine@sha256:6accb31dc932f9233f00dc59034a01f7acce76353476fb9e467dad86de5a4e3e";

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
