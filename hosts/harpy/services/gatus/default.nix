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
        image = "ghcr.io/twin/gatus:v5.33.0@sha256:bf249f4d7cf69e825457ade2ebc3d11168d73527ef1657a653119a0d9da97a4a";

        environmentFiles = [ config.sops.secrets."gatus/env".path ];

        environment = {
          GATUS_LOG_LEVEL = "WARN";
        };

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
