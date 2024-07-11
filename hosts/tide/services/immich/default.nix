{ config, ... }: {
  disko.devices.zpool.storage.datasets."services/immich".type = "zfs_fs";
  disko.devices.zpool.storage.datasets."services/immich/postgres".type = "zfs_fs";

  sops.secrets."immich/env" = { };

  virtualisation.oci-containers.containers.immich = {
    image = "ghcr.io/immich-app/immich-server:v1.108.0@sha256:248a6da7dadeb57f90eacd5635ecc65e63d4c3646a6c94a362bb57cba1b314fa";

    volumes = [
      "/storage/services/immich:/usr/src/app/upload"
      "/etc/localtime:/etc/localtime:ro"
    ];

    environmentFiles = [ config.sops.secrets."immich/env".path ];

    environment = {
      DB_HOSTNAME = "immich-postgres";
      DB_USERNAME = "immich";
      DB_DATABASE_NAME = "immich";
      REDIS_HOSTNAME = "immich-redis";
    };

    extraOptions = [ "--device=/dev/dri" ];

    dependsOn = [ "immich-redis" "immich-postgres" ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.immich.rule" = "Host(`immich.x.auxves.dev`)";
      "traefik.http.services.immich.loadbalancer.server.port" = "3001";
    };
  };

  virtualisation.oci-containers.containers.immich-machine-learning = {
    image = "ghcr.io/immich-app/immich-machine-learning:v1.108.0@sha256:4dc544396bf08cd92066f83a270155201d80512add127ca9fac2d3e56694d2a4";
  };

  virtualisation.oci-containers.containers.immich-redis = {
    image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";

    extraOptions = [
      "--health-cmd=redis-cli ping || exit 1"
    ];
  };

  sops.secrets."immich/postgres/env" = { };

  virtualisation.oci-containers.containers.immich-postgres = {
    image = "tensorchord/pgvecto-rs:pg16-v0.2.1@sha256:ff2288833f32aa863ba46f4c6f5b5c143f526a2d27f4cca913c232f917a66602";

    volumes = [
      "/storage/services/immich/postgres:/var/lib/postgresql/data"
    ];

    environmentFiles = [ config.sops.secrets."immich/postgres/env".path ];

    environment = {
      POSTGRES_USER = "immich";
      POSTGRES_DB = "immich";
      POSTGRES_INITDB_ARGS = "--data-checksums";
    };
  };
}