{ config, ... }:
let
  cfg = config.apps.riven;
in
{
  sops.secrets."riven/zurg.config.yaml" = { };

  apps.riven = { lib', ... }: {
    volumes = {
      backend = { type = "zfs"; };
      postgres = { type = "zfs"; };

      library = { type = "zfs"; path = "/storage/media"; };
      rd = { type = "ephemeral"; path = "/var/lib/realdebrid"; };
      zurg = { type = "ephemeral"; path = "/var/cache/zurg"; };
    };

    containers = {
      riven = {
        image = "spoked/riven:0.21.19@sha256:50103b140949df86ebba8104fa31af4c7e8c902a80b97cb53d562b15320a02a7";

        environment = {
          PUID = "0";
          PGID = "0";
          RIVEN_FORCE_ENV = "true";
          RIVEN_DATABASE_HOST = "postgresql+psycopg2://postgres@${cfg.containers.postgres.fullName}/riven";
        };

        volumes = [
          "${cfg.volumes.backend.path}:/riven/data"
          "${cfg.volumes.library.path}:/mnt/library"
          "${cfg.volumes.rd.path}:/data/rd:rshared"
        ];

        dependsOn = [
          cfg.containers.postgres.fullName
          cfg.containers.rclone.fullName
        ];
      };

      frontend = {
        image = "spoked/riven-frontend:0.20.0@sha256:2e4ddd26dca86d85237f059c70786ab917d1f0cedff906c90dc4b457bae32a8d";

        environment = {
          BACKEND_URL = "http://${cfg.containers.riven.fullName}:8080";
          DIALECT = "postgres";
          DATABASE_URL = "postgres://postgres@${cfg.containers.postgres.fullName}/riven";
        };

        dependsOn = [ cfg.containers.postgres.fullName ];
      };

      postgres = lib'.mkPostgres {
        db = "riven";
        data = cfg.volumes.postgres.path;
      };

      zurg = {
        image = "ghcr.io/debridmediamanager/zurg-testing:v0.9.3-final@sha256:5c47ef99443ac67c9a5ede82204b5be75d30eb25b4ac4885b6612d7526243baa";

        volumes = [
          "${config.sops.secrets."riven/zurg.config.yaml".path}:/app/config.yml"
          "${cfg.volumes.zurg.path}:/app/data"
        ];
      };

      rclone = {
        image = "rclone/rclone:1.69.2@sha256:df9f8f0115e2816b18099c28a629e6914c84915b55aeddd2db58df8cf6b76d34";

        volumes = [
          "${./rclone.conf}:/config/rclone/rclone.conf"
          "${cfg.volumes.rd.path}:/data:rshared"
        ];

        cmd = [
          "mount"
          "zurg:"
          "/data"
          "--allow-other"
          "--allow-non-empty"
          "--dir-cache-time=10s"
          "--vfs-cache-mode=full"
        ];

        extraOptions = [ "--privileged" ];
      };
    };

    ingresses = {
      app = {
        container = "frontend";
        port = 3000;
      };
    };
  };

  monitoring.checks = [{
    name = "riven-frontend";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
