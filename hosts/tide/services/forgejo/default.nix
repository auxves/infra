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
        image = "codeberg.org/forgejo/forgejo:12.0.2@sha256:07d9dad5773ae40cdfc00bede6e35dce3889d22661f0f66b96999885ea5e2467";

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
