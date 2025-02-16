{ config, ... }:
let
  cfg = config.apps.forgejo;
in
{
  sops.secrets."forgejo/runner-env" = { };

  apps.forgejo = {
    volumes = {
      forgejo = { type = "zfs"; };
    };

    containers = {
      forgejo = {
        image = "codeberg.org/forgejo/forgejo:10.0.1@sha256:7bb6f1e34a5669f634948ecb613c301bf756de93e8ecc1247d57012d4d649e64";

        volumes = [
          "${cfg.volumes.forgejo.path}:/data"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
    };

    ingress = {
      container = "forgejo";
      domain = "git.auxves.dev";
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
