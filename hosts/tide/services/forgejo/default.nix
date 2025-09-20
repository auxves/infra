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
        image = "codeberg.org/forgejo/forgejo:12.0.4@sha256:dbb0f88677f0c65cd1b66fb83504225aa5a04c4bc4a5ffdf9fc9a3a6d5bb1c68";

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
