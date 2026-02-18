{ config, ... }:
let
  cfg = config.apps.open-webui;
in
{
  sops.secrets."open-webui/env" = { };

  apps.open-webui = { lib', ... }: {
    volumes = {
      data = { type = "zfs"; };
    };

    containers = {
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:v0.8.3@sha256:205e9cf23b66553643b065afcdeffb7f86b35bf36e0ce643dc56946a911954b7";

        volumes = [
          "${cfg.volumes.data.path}:/app/backend/data"
        ];

        environment = {
          WEBUI_URL = "https://${cfg.ingresses.app.domain}";
          ENABLE_OAUTH_PERSISTENT_CONFIG = "false";
          ENABLE_OAUTH_SIGNUP = "true";
          ENABLE_LOGIN_FORM = "false";
          OPENID_PROVIDER_URL = "https://${config.apps.pocket-id.ingresses.app.domain}/.well-known/openid-configuration";
          OAUTH_PROVIDER_NAME = "Auxves ID";
          OAUTH_SCOPES = "openid email profile groups";
          OAUTH_UPDATE_PICTURE_ON_LOGIN = "true";
          ENABLE_OAUTH_ROLE_MANAGEMENT = "true";
          OAUTH_ROLES_CLAIM = "groups";
          OAUTH_ADMIN_ROLES = "admin";
        };

        environmentFiles = [ config.sops.secrets."open-webui/env".path ];
      };
    };

    ingresses = {
      app = {
        domain = "ai.auxves.dev";
        container = "open-webui";
        port = 8080;
      };
    };
  };

  monitoring.checks = [{
    name = "open-webui";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
