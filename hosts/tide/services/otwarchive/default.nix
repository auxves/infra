{ config, ... }:
let
  cfg = config.apps.otwarchive;
in
{
  sops.secrets."otwarchive/env" = { };
  sops.secrets."otwarchive/db/env" = { };

  apps.otwarchive = { lib', ... }: {
    volumes = {
      config = { type = "zfs"; };

      db = { type = "zfs"; };
      es = { type = "ephemeral"; };
    };

    containers = {
      otwarchive = {
        image = "ghcr.io/auxves/otwarchive-docker:v0.9.468.4@sha256:060665d5b4a484b9e19802adb04bb992b682108893896b1768ec8b6d6bc70a42";

        volumes = [
          "${cfg.volumes.config.path}/database.yml:/otwa/config/database.yml"
          "${cfg.volumes.config.path}/local.yml:/otwa/config/local.yml"
          "${cfg.volumes.config.path}/redis.yml:/otwa/config/redis.yml"
        ];

        environment = {
          RAILS_ENV = "development";
          RAILS_DEVELOPMENT_HOSTS = cfg.ingresses.app.domain;
        };

        environmentFiles = [ config.sops.secrets."otwarchive/env".path ];

        cmd = [
          "bundle"
          "exec"
          "rails"
          "s"
          "-p=3000"
          "-b=0.0.0.0"
          "--no-log-to-stdout"
        ];

        dependsOn = [
          cfg.containers.db.fullName
          cfg.containers.redis.fullName
          cfg.containers.es.fullName
        ];
      };

      resque = {
        image = "ghcr.io/auxves/otwarchive-docker:v0.9.468.4@sha256:060665d5b4a484b9e19802adb04bb992b682108893896b1768ec8b6d6bc70a42";

        volumes = [
          "${cfg.volumes.config.path}/database.yml:/otwa/config/database.yml"
          "${cfg.volumes.config.path}/local.yml:/otwa/config/local.yml"
          "${cfg.volumes.config.path}/redis.yml:/otwa/config/redis.yml"
        ];

        environment = {
          RAILS_ENV = "development";
          QUEUE = "*";
        };

        environmentFiles = [ config.sops.secrets."otwarchive/env".path ];

        cmd = [
          "bash"
          "-c"
          "bundle exec rake environment resque:scheduler & bundle exec rake environment resque:work"
        ];

        dependsOn = [
          cfg.containers.db.fullName
          cfg.containers.redis.fullName
        ];
      };

      db = {
        image = "docker.io/mariadb:10.5.4-focal@sha256:35d51577112c983a6d3384a39f8349b58b0d25d6ddaa59d34a491d9570d435bb";

        volumes = [ "${cfg.volumes.db.path}:/var/lib/mysql" ];

        environmentFiles = [ config.sops.secrets."otwarchive/db/env".path ];

        cmd = [
          "mysqld"
          "--sql-mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
        ];
      };

      redis = {
        image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";
      };

      es = {
        image = "docker.io/elasticsearch:9.3.0@sha256:d6dbcf006047aafb87719e6e0b673c2067a760c902bd207059e84b27b22e2bb2";

        environment = {
          "discovery.type" = "single-node";
          "xpack.security.enabled" = "false";
          "ES_JAVA_OPTS" = "-Xms512m -Xmx512m";
        };

        volumes = [ "${cfg.volumes.es.path}:/usr/share/elasticsearch/data" ];
      };
    };

    ingresses = {
      app = {
        container = "otwarchive";
        port = 3000;
      };
    };
  };

  monitoring.checks = [{
    name = "otwarchive";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
