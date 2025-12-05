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
        image = "tomsquest/docker-radicale:3.5.9.0@sha256:b833f12e7fe02ef5fcb841bf331785b865325924c22e375b34279b96b29cf7b6";
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
