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
          image = "traefik:v3.7.16@sha256:c8a121e4bb1347e8fd52657fab12f2cb70b68f8a018895e2068f92c9e519b9c2";

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

          metrics.port = 8080;
        };
      };

      ingresses = {
        app = {
          container = "traefik";
          port = 9999;

          settings = {
            service = "api@internal";
            "tls.certresolver" = "letsencrypt";
            "tls.domains[0].main" = "${config.networking.hostName}.x.auxves.dev";
            "tls.domains[0].sans" = "*.${config.networking.hostName}.x.auxves.dev";
          };
        };
      };
    };
  };
}
