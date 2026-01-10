{ lib, config, pkgs, ... }:
let
  cfg = config.apps.ao3;
in
{
  sops.secrets."ao3/env" = { };

  apps.ao3 = {
    volumes = {
      pocketbase = { type = "zfs"; path = "/storage/services/ao3/pocketbase"; };

      archive = { type = "zfs"; path = "/storage/media/fics/ao3"; };
    };

    containers = {
      pocketbase = {
        image = "ghcr.io/muchobien/pocketbase:0.35.1@sha256:05d2aa0a38dfc7b50c8f2a2993967b58fb64b696434c19efa6a83562c3eafafe";

        volumes = [
          "${cfg.volumes.pocketbase.path}:/pb_data"
        ];
      };

      archival = {
        autoStart = false;

        image = "sync-ao3:latest";
        imageStream = pkgs.dockerTools.streamLayeredImage {
          name = "sync-ao3";
          tag = "latest";
          contents = with pkgs.dockerTools; [ binSh caCertificates ];
          config.Cmd = [ "${pkgs.scripts.sync-ao3}/bin/sync-ao3" ];
        };

        environment = {
          STATE_DIR = "/state";
          LOG_LEVEL = "DEBUG";
        };

        environmentFiles = [ config.sops.secrets."ao3/env".path ];

        volumes = [
          "${cfg.volumes.archive.path}:/state"
        ];
      };
    };

    ingresses = {
      pocketbase = {
        container = "pocketbase";
        port = 8090;
      };
    };
  };

  systemd.services.podman-ao3-archival = {
    startAt = "*-*-* 04:00:00 America/Los_Angeles";
    serviceConfig.Restart = lib.mkForce "no";
  };
}
