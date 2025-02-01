{ self, config, pkgs, ... }:
let
  cfg = config.apps.gatus;

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
    #   redirect-url = "https://status.auxves.dev/authorization-code/callback";
    #   client-id = "$OIDC_CLIENT_ID";
    #   client-secret = "$OIDC_CLIENT_SECRET";
    #   scopes = [ "openid" ];
    # };
  };
in
{
  sops.secrets."gatus/env" = { };

  apps.gatus = {
    volumes = {
      gatus = { type = "ephemeral"; };
    };

    containers = {
      gatus = {
        image = "ghcr.io/twin/gatus:v5.15.0@sha256:45686324db605e57dfa8b0931d8d57fe06298f52685f06aa9654a1f710d461bb";

        environmentFiles = [ config.sops.secrets."gatus/env".path ];

        volumes = [
          "${cfg.volumes.gatus.path}:/data"
          "${yaml.generate "gatus.yaml" gatusConfig}:/config/config.yaml"
        ];
      };
    };

    ingress = {
      container = "gatus";
      domain = "status.auxves.dev";
      port = 8080;
    };
  };
}
