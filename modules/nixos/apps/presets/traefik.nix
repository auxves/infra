{ config, lib, pkgs, ... }:
let
  presetCfg = config.presets.apps.traefik;
  cfg = config.apps.traefik;

  yaml = pkgs.formats.yaml { };

  configFile = yaml.generate "traefik.yaml" {
    entryPoints = {
      internal = {
        address = ":443";
        asDefault = true;
        http = {
          tls = { certResolver = "letsencrypt"; };
        };
        transport.respondingTimeouts.readTimeout = "0s";

        # QUIC currently doesn't work over Tailscale
        # http3 = { advertisedPort = 443; };
      };

      public = {
        address = ":8443";
        http = {
          tls = { certResolver = "letsencrypt"; };
        };
        transport.respondingTimeouts.readTimeout = "0s";
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
  options.presets.apps.traefik = with lib; {
    enable = mkEnableOption "Enable traefik";
  };

  config = lib.mkIf (presetCfg.enable) {
    sops.secrets."traefik/env" = { };

    apps.traefik = {
      volumes = {
        traefik = { type = "ephemeral"; };
      };

      containers = {
        traefik = {
          image = "traefik:v3.7.15@sha256:0f6150202bc1fed72a7bd2107460eaa510e5b8a905f3fdb5b84f2c8619c33368";

          ports = lib.optionals (config.meta.addresses.internal.v6 != null) [
            # Internal
            "[${config.meta.addresses.internal.v6}]:443:443/tcp"
            "[${config.meta.addresses.internal.v6}]:443:443/udp"
          ] ++ lib.optionals (config.meta.addresses.internal.v4 != null) [
            # Internal
            "${config.meta.addresses.internal.v4}:443:443/tcp"
            "${config.meta.addresses.internal.v4}:443:443/udp"
          ];

          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "${cfg.volumes.traefik.path}:/etc/traefik"
            "${configFile}:/etc/traefik/traefik.yaml"
          ];

          environmentFiles = [ config.sops.secrets."traefik/env".path ];

          labels = {
            "traefik.http.routers.traefik-app.service" = "api@internal";
            "traefik.http.routers.traefik-app.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.traefik-app.tls.domains[0].main" = "${config.networking.hostName}.x.auxves.dev";
            "traefik.http.routers.traefik-app.tls.domains[0].sans" = "*.${config.networking.hostName}.x.auxves.dev";
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
  };
}
