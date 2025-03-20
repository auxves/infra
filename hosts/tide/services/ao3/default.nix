{ config, pkgs, ... }: {
  sops.secrets."ao3/db-env" = { };

  apps.ao3-db = {
    volumes = {
      data = { type = "zfs"; path = "/storage/services/ao3/db"; };
    };

    containers = {
      resty-kv = {
        image = "resty-kv:latest";
        imageStream = pkgs.dockerTools.streamLayeredImage {
          name = "resty-kv";
          tag = "latest";
          contents = with pkgs.dockerTools; [ binSh caCertificates ];
          config.Entrypoint = [ "${pkgs.resty-kv}/bin/resty-kv" ];
        };

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
