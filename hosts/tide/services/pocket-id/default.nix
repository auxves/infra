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
        image = "ghcr.io/pocket-id/pocket-id:v1.8.0@sha256:a18c62cfc2bf9ca8e99d22e37d7dd511d5c07ec44933a9b71075d3e1a8e12b05";

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
