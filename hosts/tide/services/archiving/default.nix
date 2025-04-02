{ lib, config, pkgs, ... }:
let
  cfg = config.apps.archiving;
in
{
  sops.secrets."ao3/env" = { };

  apps.archiving = {
    volumes = {
      ao3 = { type = "zfs"; path = "/storage/media/books/ao3"; };
    };

    containers = {
      ao3 = {
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
          "${cfg.volumes.ao3.path}:/state"
        ];
      };
    };
  };

  systemd.services.podman-archiving-ao3 = {
    startAt = "*-*-* 04:00:00 America/Los_Angeles";
    serviceConfig.Restart = lib.mkForce "no";
  };
}
