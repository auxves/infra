{ config, osConfig, lib, pkgs, ... }:
let
  cfg = config.presets.traefik;

  yaml = pkgs.formats.yaml { };

  configFile = yaml.generate "traefik.yaml" {
    entryPoints = {
      internal = {
        address = ":443";
        asDefault = true;
        http = {
          tls = { certResolver = "letsencrypt"; };
        };
        http3 = { advertisedPort = 443; };
      };

      public = {
        address = ":8443";
        http = {
          tls = { certResolver = "letsencrypt"; };
        };
        http3 = { advertisedPort = 443; };
      };
    };

    certificatesResolvers = {
      letsencrypt = {
        acme = {
          dnsChallenge = {
            provider = "cloudflare";
            resolvers = [ "1.1.1.1:53" "9.9.9.9:53" ];
          };
          email = "me@auxves.dev";
          storage = "/etc/traefik/acme.json";
        };
      };
    };

    providers.docker = {
      exposedByDefault = false;
    };

    api.insecure = true;

    metrics.prometheus = { };

    serversTransport.insecureSkipVerify = true;

    log = {
      level = "INFO";
      format = "json";
    };
  };
in
{
  options.presets.traefik = with lib; {
    enable = mkEnableOption "Enable traefik";
  };

  config = lib.mkIf (cfg.enable) {
    volumes = {
      traefik = { type = "ephemeral"; };
    };

    containers = {
      traefik = {
        image = "traefik:v3.3.3@sha256:f1fdee7fda041872cff24e36a08f45ca53f006ded88f743a8e30e3d87ca52b48";

        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock:ro"
          "${config.volumes.traefik.path}:/etc/traefik"
          "${configFile}:/etc/traefik/traefik.yaml:ro"
        ];

        environmentFiles = [ osConfig.sops.secrets."traefik/env".path ];

        labels = {
          "traefik.http.routers.traefik.service" = "api@internal";
          "traefik.http.routers.traefik.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.traefik.tls.domains[0].main" = "${config.ingress.domain}";
          "traefik.http.routers.traefik.tls.domains[0].sans" = "*.${config.ingress.domain}";
        };

        metrics.port = 8080;
      };
    };

    ingress = {
      container = "traefik";
      port = 9999;
    };
  };
}
