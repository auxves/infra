{ config, ... }:
let
  cfg = config.apps.radicale;
in
{
  apps.radicale = {
    volumes = {
      radicale = { type = "zfs"; };
    };

    containers = {
      radicale = {
        image = "tomsquest/docker-radicale:3.7.2.0@sha256:df3ab2f20caac6ba9bc19ff6f7285a2ae64d9d430fd4e102f36a859c9e751953";
        volumes = [
          "${cfg.volumes.radicale.path}:/data"
          "${./radicale.conf}:/config/config"
        ];
      };
    };

    ingresses = {
      app = {
        domain = "radicale.auxves.dev";
        container = "radicale";
        port = 5232;
      };
    };
  };

  monitoring.checks = [{
    name = "radicale";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
