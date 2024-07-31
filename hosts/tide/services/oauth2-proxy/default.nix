{ config, pkgs, ... }:
let
  headers = builtins.concatStringsSep "," [
    "x-auth-request-preferred-username"
    "x-auth-request-email"
    "x-auth-request-groups"
    "x-auth-request-user"
  ];
in
{
  sops.secrets."oauth2-proxy/env" = { };

  virtualisation.oci-containers.containers.oauth2-proxy = {
    image = "oauth2-proxy:custom";
    imageFile = pkgs.oauth2-proxy-image;

    environment = {
      OAUTH2_PROXY_HTTP_ADDRESS = "0.0.0.0:4180";
      OAUTH2_PROXY_WHITELIST_DOMAINS = "*.x.auxves.dev";
      OAUTH2_PROXY_UPSTREAMS = "static://202";
      OAUTH2_PROXY_EMAIL_DOMAINS = "*";
      OAUTH2_PROXY_PROVIDER = "oidc";
      OAUTH2_PROXY_REDIRECT_URL = "https://proxy.x.auxves.dev/oauth2/callback";
      OAUTH2_PROXY_OIDC_ISSUER_URL = "https://auth.auxves.dev";
      OAUTH2_PROXY_OIDC_GROUPS_CLAIM = "roles";
      OAUTH2_PROXY_ALLOWED_GROUPS = "/admin|admin";
      OAUTH2_PROXY_PASS_ACCESS_TOKEN = "true";
      OAUTH2_PROXY_REVERSE_PROXY = "true";
      OAUTH2_PROXY_SET_XAUTHREQUEST = "true";
      OAUTH2_PROXY_SKIP_PROVIDER_BUTTON = "true";
      OAUTH2_PROXY_CODE_CHALLENGE_METHOD = "S256";
      OAUTH2_PROXY_COOKIE_DOMAINS = "x.auxves.dev";
    };

    environmentFiles = [ config.sops.secrets."oauth2-proxy/env".path ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.oauth2-proxy.rule" = "Host(`proxy.x.auxves.dev`)";
      "traefik.http.services.oauth2-proxy.loadbalancer.server.port" = "4180";

      "traefik.http.middlewares.auth.forwardauth.address" = "http://oauth2-proxy:4180";
      "traefik.http.middlewares.auth.forwardauth.trustForwardHeader" = "true";
      "traefik.http.middlewares.auth.forwardauth.authResponseHeaders" = headers;

      "traefik.http.middlewares.auth-admin.forwardauth.address" = "http://oauth2-proxy:4180/admin";
      "traefik.http.middlewares.auth-admin.forwardauth.trustForwardHeader" = "true";
      "traefik.http.middlewares.auth-admin.forwardauth.authResponseHeaders" = headers;
    };
  };
}
