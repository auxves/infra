{ self, config, pkgs, ... }:
let
  yaml = pkgs.formats.yaml { };

  endpoints = builtins.concatMap
    (host: host.cfg.monitoring.endpoints)
    (builtins.attrValues self.hosts);

  gatusConfig = {
    inherit endpoints;

    alerting.discord = {
      webhook-url = "$DISCORD_WEBHOOK_URL";
      default-alert = {
        send-on-resolved = true;
        failure-threshold = 3;
        success-threshold = 2;
      };
    };

    security.oidc = {
      issuer-url = "https://auth.auxves.dev";
      redirect-url = "https://status.x.auxves.dev/authorization-code/callback";
      client-id = "$OIDC_CLIENT_ID";
      client-secret = "$OIDC_CLIENT_SECRET";
      scopes = [ "openid" ];
    };
  };
in
{
  sops.secrets."gatus/env" = { };

  virtualisation.oci-containers.containers.gatus = {
    image = "ghcr.io/twin/gatus:v5.12.1@sha256:3a380d56c035ea11328fe66716aae9ceb2ccaca7be2c126c40bbe6987d2f85af";

    environmentFiles = [ config.sops.secrets."gatus/env".path ];

    volumes = [
      "${yaml.generate "gatus.yaml" gatusConfig}:/config/config.yaml"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.gatus.rule" = "Host(`status.x.auxves.dev`)";
    };
  };
}
