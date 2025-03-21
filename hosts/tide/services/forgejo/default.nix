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
        image = "codeberg.org/forgejo/forgejo:10.0.2@sha256:95c46edf71cef1b18500fce60313b4d7f7652ea7d78ba71033155efc25f16093";

        environment = {
          FORGEJO__SERVER__DOMAIN = cfg.ingress.domain;
          FORGEJO__SERVER__ROOT_URL = "https://${cfg.ingress.domain}/";
        };

        volumes = [
          "${cfg.volumes.forgejo.path}:/data"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
    };

    ingress = {
      container = "forgejo";
      domain = "forge.auxves.dev";
      port = 3000;
    };
  };

  monitoring.checks = [{
    name = "forgejo";
    group = "services";
    url = "https://${cfg.ingress.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
