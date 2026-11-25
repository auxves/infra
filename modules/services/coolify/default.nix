{ config, lib, ... }: {
  flake.dns.records."*.dev.auxves.dev" =
    let addrs = config.flake.hosts.tide.cfg.meta.addresses.internal; in
    lib.optionals (addrs.v4 != null) [
      { type = "A"; value = addrs.v4; }
    ] ++ lib.optionals (addrs.v6 != null) [
      { type = "AAAA"; value = addrs.v6; }
    ];

  flake.modules.nixos.tide = { config, lib, pkgs, ... }:
    let
      cfg = config.apps.coolify;

      yaml = pkgs.formats.yaml { };

      devDynamicConfig = yaml.generate "coolify-dev.yaml" {
        http = {
          routers = {
            coolify-dev = {
              rule = "HostRegexp(`^[^.]+\\.dev\\.auxves\\.dev$`)";
              entryPoints = [ "internal" ];
              service = "coolify-dev";
              tls = {
                certResolver = "letsencrypt";
                domains = [
                  {
                    main = "*.dev.auxves.dev";
                    sans = [ "dev.auxves.dev" ];
                  }
                ];
              };
            };
          };

          services = {
            coolify-dev = {
              loadBalancer = {
                servers = [{ url = "https://${config.containers.coolify-dev.localAddress}:443"; }];
              };
            };
          };
        };
      };
    in
    {
      sops.secrets."coolify/env" = { };

      apps.coolify = {
        volumes = {
          coolify = { type = "zfs"; };
          postgres = { type = "zfs"; };
          redis = { type = "zfs"; };
        };

        containers = {
          coolify = {
            image = "coollabsio/coolify:4.7.6@sha256:95d25ed900d0f0cb6e621c3bade63efdf1df85ba5c63e76ae3c92beba1debb90";

            volumes = [
              "${config.sops.secrets."coolify/env".path}:/var/www/html/.env:ro"
              "${cfg.volumes.coolify.path}/ssh:/var/www/html/storage/app/ssh"
              "${cfg.volumes.coolify.path}/applications:/var/www/html/storage/app/applications"
              "${cfg.volumes.coolify.path}/databases:/var/www/html/storage/app/databases"
              "${cfg.volumes.coolify.path}/services:/var/www/html/storage/app/services"
              "${cfg.volumes.coolify.path}/backups:/var/www/html/storage/app/backups"
              "${cfg.volumes.coolify.path}/images:/var/www/html/storage/app/images"
            ];

            environment = {
              APP_NAME = "Coolify";
              APP_ENV = "production";
              APP_URL = "https://${cfg.ingresses.app.domain}";
              DB_HOST = cfg.containers.postgres.fullName;
              DB_PORT = "5432";
              DB_DATABASE = "coolify";
              DB_USERNAME = "coolify";
              REDIS_HOST = cfg.containers.redis.fullName;
              REDIS_PORT = "6379";
              PUSHER_BACKEND_PORT = "6001";
            };

            dependsOn = [ cfg.containers.postgres.fullName cfg.containers.redis.fullName ];
          };

          postgres = {
            image = "postgres:16-alpine@sha256:de3d7b6e4b5b3fe899e997579d6dfe95a99539d154abe03f0b6839133ed05065";

            volumes = [
              "${cfg.volumes.postgres.path}:/var/lib/postgresql/data"
            ];

            environment = {
              POSTGRES_USER = "coolify";
              POSTGRES_DB = "coolify";
            };

            environmentFiles = [ config.sops.secrets."coolify/env".path ];
          };

          redis = {
            image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";

            volumes = [
              "${cfg.volumes.redis.path}:/data"
            ];

            cmd = [ "sh" "-c" "exec redis-server --save 20 1 --loglevel warning --requirepass \"$REDIS_PASSWORD\"" ];

            environmentFiles = [ config.sops.secrets."coolify/env".path ];
          };
        };

        ingresses = {
          app = {
            container = "coolify";
            port = 8080;
          };

          realtime = {
            container = "coolify";
            port = 6001;
            domain = cfg.ingresses.app.domain;

            settings = {
              rule = "Host(`${cfg.ingresses.app.domain}`) && PathPrefix(`/app`)";
              priority = 100;
            };
          };

          terminal = {
            container = "coolify";
            port = 6002;
            domain = cfg.ingresses.app.domain;

            settings = {
              rule = "Host(`${cfg.ingresses.app.domain}`) && PathPrefix(`/terminal/ws`)";
              priority = 100;
            };
          };
        };
      };

      traefik.dynamicConfigs = [ devDynamicConfig ];

      monitoring.checks = [{
        name = "coolify";
        group = "services";
        url = "https://${cfg.ingresses.app.domain}/api/health";
        interval = "1m";
        alerts = [{ type = "discord"; }];
        conditions = [
          "[STATUS] == 200"
        ];
      }];
    };
}
