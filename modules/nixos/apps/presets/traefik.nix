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
        image = "traefik:v3.4.3@sha256:f3de2b96ec6b1cc987619c4d1d65d7e8140862eb0bbfc5f0e2e563691e8787d8";

        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${config.volumes.traefik.path}:/etc/traefik"
          "${configFile}:/etc/traefik/traefik.yaml"
        ];

        environmentFiles = [ osConfig.sops.secrets."traefik/env".path ];

        labels = {
          "traefik.http.routers.traefik-app.service" = "api@internal";
          "traefik.http.routers.traefik-app.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.traefik-app.tls.domains[0].main" = "${osConfig.networking.hostName}.x.auxves.dev";
          "traefik.http.routers.traefik-app.tls.domains[0].sans" = "*.${osConfig.networking.hostName}.x.auxves.dev";
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
