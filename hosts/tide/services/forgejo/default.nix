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
        image = "codeberg.org/forgejo/forgejo:11.0.2@sha256:7c061fccf20f8e422d886fb4a99aa6f3083fde13c40d78ddac67a83e0d4349f4";

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
