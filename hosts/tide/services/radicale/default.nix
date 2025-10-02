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
        image = "tomsquest/docker-radicale:3.5.7.0@sha256:ed0bc36eb284ae7ad6e81d0f00b4f477c025e3ed22e780ca683a80b35102a66e";
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
