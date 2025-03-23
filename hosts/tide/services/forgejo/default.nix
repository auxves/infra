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
        image = "codeberg.org/forgejo/forgejo:10.0.3@sha256:99b6c15a1bc98e623103a83a04023662a93fd035dac4f0a856d781afa9d71095";

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
