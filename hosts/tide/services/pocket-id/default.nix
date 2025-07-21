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
        image = "ghcr.io/pocket-id/pocket-id:v1.6.4@sha256:da768baa319f23d6815d048d0d49ce4aacd9eea15ad46d48a5c01ca15fbde392";

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
