{ config, ... }:
let
  cfg = config.apps.forgejo;
in
{
  apps.forgejo = {
    volumes = {
      forgejo = { type = "zfs"; };
    };

    containers = {
      forgejo = {
        image = "codeberg.org/forgejo/forgejo:15.0.1@sha256:bff07e43f5c84449e9dc6dca2c0a16c6f9eb285405d7f1bc631a360fd963f3fc";

        environment = {
          FORGEJO__SERVER__DOMAIN = cfg.ingresses.app.domain;
          FORGEJO__SERVER__ROOT_URL = "https://${cfg.ingresses.app.domain}/";
        };

        volumes = [
          "${cfg.volumes.forgejo.path}:/data"
        ];
      };
    };

    ingresses = {
      app = {
        type = "public";
        domain = "forge.auxves.dev";
        container = "forgejo";
        port = 3000;
      };
    };
  };

  monitoring.checks = [{
    name = "forgejo";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
