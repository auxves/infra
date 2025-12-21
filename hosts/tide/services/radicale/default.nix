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
        image = "tomsquest/docker-radicale:3.5.10.0@sha256:e9d49beb7e459a915a9e828daf22db54d00c5835b4f57ff29419776870fd8687";
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
