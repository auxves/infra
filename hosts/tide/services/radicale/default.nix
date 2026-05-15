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
        image = "tomsquest/docker-radicale:3.7.3.0@sha256:265195d889c122bb64367a84ce36ff5dc3ab88b6f5a26321af7d41be6a5da2d0";
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
