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
        image = "ghcr.io/twin/gatus:v5.25.2@sha256:9ff09fe5eb5e96b7f2126dc95b375a87a7bc16380d5cb9d798af4e0ef36f0049";

        environmentFiles = [ config.sops.secrets."gatus/env".path ];

        volumes = [
          "${cfg.volumes.gatus.path}:/data"
          "${yaml.generate "gatus.yaml" gatusConfig}:/config/config.yaml"
        ];

        metrics.port = 8080;
      };
    };

    ingresses = {
      app = {
        domain = "status.auxves.dev";
        container = "gatus";
        port = 8080;
      };
    };
  };

  monitoring.checks = [{
    name = "healthcheck";
    group = "infra";
    url = "$GATUS_HEALTHCHECK_ENDPOINT";
    interval = "2m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
