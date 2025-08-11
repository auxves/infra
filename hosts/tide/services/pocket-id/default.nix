{ config, ... }:
let
  cfg = config.apps.pocket-id;
in
{
  apps.pocket-id = {
    volumes = {
      data = { type = "zfs"; };
    };

    containers = {
      pocket-id = {
        image = "ghcr.io/pocket-id/pocket-id:v1.7.0@sha256:b3ef0b22402b34815a7aeba800ca642baa8eafdd887677b884a1e5a8c81558aa";

        volumes = [
          "${cfg.volumes.data.path}:/app/data"
        ];

        environment = {
          APP_URL = "https://${cfg.ingresses.app.domain}";
          TRUST_PROXY = "true";
          PUID = "0";
          PGID = "0";
        };
      };
    };

    ingresses = {
      app = {
        type = "public";
        domain = "id.auxves.dev";
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
}
