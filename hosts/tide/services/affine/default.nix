{ config, ... }:
let
  paths = config.storage.paths;

  hostname = "affine.x.auxves.dev";
in
{
  storage.paths."services/affine" = { };
  sops.secrets."affine/env" = { };

  virtualisation.oci-containers.containers.affine = {
    image = "ghcr.io/toeverything/affine-graphql:stable@sha256:396f81415c2394c9718f25f9f39d0fdc07389cb24548a482c103017730e4d742";

    volumes = [
      "${paths."services/affine".path}:/root/.affine"
    ];

    environmentFiles = [ config.sops.secrets."affine/env".path ];

    environment = {
      AFFINE_SERVER_EXTERNAL_URL = "https://${hostname}";
      REDIS_SERVER_HOST = "affine-redis";

      OAUTH_OIDC_SCOPE = "openid email profile offline_access";
      OAUTH_OIDC_CLAIM_MAP_ID = "preferred_username";
      OAUTH_OIDC_CLAIM_MAP_EMAIL = "email";
    };

    cmd = [
      "sh"
      "-c"
      "node ./scripts/self-host-predeploy.js && node --import ./scripts/register.js ./dist/index.js"
    ];

    dependsOn = [ "affine-redis" "affine-postgres" ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.affine.rule" = "Host(`${hostname}`)";
      "traefik.http.services.affine.loadbalancer.server.port" = "3010";
    };
  };

  monitoring.checks = [{
    name = "affine";
    group = "services";
    url = "https://${hostname}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];

  virtualisation.oci-containers.containers.affine-redis = {
    image = "redis:7.2.5@sha256:fb534a36ac2034a6374933467d971fbcbfa5d213805507f560d564851a720355";

    extraOptions = [
      "--health-cmd=redis-cli ping"
      "--health-on-failure=stop"
    ];
  };

  storage.paths."services/affine/postgres" = { };
  sops.secrets."affine/postgres/env" = { };

  virtualisation.oci-containers.containers.affine-postgres = {
    image = "postgres:16-alpine@sha256:de3d7b6e4b5b3fe899e997579d6dfe95a99539d154abe03f0b6839133ed05065";

    volumes = [
      "${paths."services/affine/postgres".path}:/var/lib/postgresql/data"
    ];

    environmentFiles = [ config.sops.secrets."affine/postgres/env".path ];

    environment = {
      POSTGRES_USER = "postgres";
      POSTGRES_DB = "affine";
    };

    extraOptions = [
      "--health-cmd=pg_isready -d \${POSTGRES_USER} -U \${POSTGRES_DB}"
      "--health-on-failure=stop"
    ];
  };
}
