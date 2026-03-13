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
        image = "codeberg.org/forgejo/forgejo:14.0.3@sha256:8f4b1f86750e206824c669e1af17b6c6e8da9ed1a8ebda615db7526ee86d3eb2";

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
