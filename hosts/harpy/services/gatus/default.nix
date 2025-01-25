{ self, config, pkgs, ... }:
let
  paths = config.storage.paths;

  yaml = pkgs.formats.yaml { };

  endpoints = builtins.concatMap
    (host: host.cfg.monitoring.checks)
    (builtins.attrValues self.hosts);

  external-endpoints = builtins.concatMap
    (host: host.cfg.monitoring.endpoints)
    (builtins.attrValues self.hosts);

  gatusConfig = {
    inherit endpoints external-endpoints;

    metrics = true;

    storage = {
      type = "sqlite";
      path = "/data/gatus.db";
    };

    alerting.discord = {
      webhook-url = "$DISCORD_WEBHOOK_URL";
      default-alert = {
        send-on-resolved = true;
        failure-threshold = 3;
        success-threshold = 2;
      };
    };

    # security.oidc = {
    #   issuer-url = "https://auth.auxves.dev";
    #   redirect-url = "https://status.x.auxves.dev/authorization-code/callback";
    #   client-id = "$OIDC_CLIENT_ID";
    #   client-secret = "$OIDC_CLIENT_SECRET";
    #   scopes = [ "openid" ];
    # };
  };
in
{
  storage.paths."var/cache/gatus" = {
    backend = "local";
  };

  sops.secrets."gatus/env" = { };

  virtualisation.oci-containers.containers.gatus = {
    image = "ghcr.io/twin/gatus:v5.12.1@sha256:3cc4e90534c05599f07fbdf15580401aa7771fac15f51d1dc8f7de265d70d12f";

    environmentFiles = [ config.sops.secrets."gatus/env".path ];

    volumes = [
      "${paths."var/cache/gatus".path}:/data"
      "${yaml.generate "gatus.yaml" gatusConfig}:/config/config.yaml"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.gatus.rule" = "Host(`status.x.auxves.dev`)";
    };
  };
}
