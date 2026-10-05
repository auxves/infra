{ config, ... }:
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
        image = "ghcr.io/pocket-id/pocket-id:v2.18.0@sha256:323e7ef5bfacf7cf32f22f3d10ccdf48e0c97c94d67e7e40b0b996830deb5165";

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
