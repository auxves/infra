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
        image = "traefik:v3.3.5@sha256:104204dadedf5d1284f8ef8f97f705649ac81aa6f7a6c9abf13e2c59245b8abc";

        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock:ro"
          "${config.volumes.traefik.path}:/etc/traefik"
          "${configFile}:/etc/traefik/traefik.yaml:ro"
        ];

        environmentFiles = [ osConfig.sops.secrets."traefik/env".path ];

        labels = {
          "traefik.http.routers.traefik-app.service" = "api@internal";
          "traefik.http.routers.traefik-app.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.traefik-app.tls.domains[0].main" = "${config.ingresses.app.domain}";
          "traefik.http.routers.traefik-app.tls.domains[0].sans" = "*.${config.ingresses.app.domain}";
        };

        metrics.port = 8080;
      };
    };

    ingresses = {
      app = {
        container = "traefik";
        port = 9999;
      };
    };
  };
}
