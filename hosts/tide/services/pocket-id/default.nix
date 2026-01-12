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
        image = "ghcr.io/pocket-id/pocket-id:v2.2.0@sha256:84d20a801692b9635f481522df2672a7aae522726c30953dae52e17fc2696b27";

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
