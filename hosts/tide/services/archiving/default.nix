{ lib, config, pkgs, ... }:
let
  cfg = config.apps.archiving;
in
{
  sops.secrets."ao3/env" = { };

  apps.archiving = {
    volumes = {
      books = { type = "zfs"; path = "/storage/media/books"; };
      ao3 = { type = "zfs"; };
    };

    containers = {
      ao3 = {
        autoStart = false;

        image = "sync-ao3:latest";
        imageStream = pkgs.dockerTools.streamLayeredImage {
          name = "sync-ao3";
          tag = "latest";
          contents = with pkgs.dockerTools; [ binSh caCertificates ];
          config.Cmd = [ "${pkgs.sync-ao3}/bin/sync-ao3" ];
        };

        environment = {
          STATE_DIR = "/state";
          ARCHIVE_DIR = "/media/ao3";
        };

        environmentFiles = [ config.sops.secrets."ao3/env".path ];

        volumes = [
          "${cfg.volumes.ao3.path}:/state"
          "${cfg.volumes.books.path}:/media"
        ];
      };
    };
  };

  systemd.services.podman-archiving-ao3 = {
    startAt = "*:*:00";
    serviceConfig.Restart = lib.mkForce "no";
  };
}
