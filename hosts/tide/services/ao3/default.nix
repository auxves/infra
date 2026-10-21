{ lib, config, ... }:
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
        image = "ghcr.io/muchobien/pocketbase:0.40.5@sha256:618171d6df039ab3edd74ef9e6b89d43ec836fd55f5437017b7ed3790e627ab0";

        volumes = [
          "${cfg.volumes.pocketbase.path}:/pb_data"
        ];
      };

      archival = {
        autoStart = false;

        image = "forge.auxves.dev/arno/ao3-cli:v0.2.5@sha256:8cb2a6430449e58b82c1065d046374a8fc3dba470ade174c7e857fa56cb24cde";

        environment = {
          LOG_LEVEL = "DEBUG";
          AO3_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5.2 Safari/605.1.15";
        };

        environmentFiles = [ config.sops.secrets."ao3/env".path ];

        volumes = [
          "${cfg.volumes.archive.path}:/state"
        ];

        cmd = [ "bookmarks" "sync" "/state" ];

        systemd = {
          startAt = "*-*-* 04:00:00 America/Los_Angeles";
          serviceConfig.Restart = lib.mkForce "no";
          serviceConfig.RuntimeMaxSec = "2h";
        };
      };
    };

    ingresses = {
      pocketbase = {
        container = "pocketbase";
        port = 8090;
      };
    };
  };
}
