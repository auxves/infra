{ config, ... }: {
  sops.secrets."ao3/db-env" = { };

  apps.ao3-db = {
    volumes = {
      data = { type = "zfs"; path = "/storage/services/ao3/db"; };
    };

    containers = {
      resty-kv = {
        image = "ghcr.io/auxves/resty-kv:v0.1.0@sha256:77bedab2694c8c8696e8a9e28e1947db52fa8abd1d47777b6aa2c0053aa97f08";

        volumes = [
          "${config.apps.ao3-db.volumes.data.path}:/data"
        ];

        environment = {
          RESTY_KV_FILE = "/data/ao3.db";
          RESTY_KV_HOST = "0.0.0.0";
        };

        environmentFiles = [ config.sops.secrets."ao3/db-env".path ];
      };
    };

    ingress = {
      container = "resty-kv";
      port = 3000;
    };
  };
}
