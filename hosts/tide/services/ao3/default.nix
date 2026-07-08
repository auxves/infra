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
        image = "ghcr.io/muchobien/pocketbase:0.36.7@sha256:244e8028be1fc9a9ab3649e746c248f40dd0cf852f7cdc8b12e17922347f52cf";

        volumes = [
          "${cfg.volumes.pocketbase.path}:/pb_data"
        ];
      };

      archival = {
        autoStart = false;

        image = "forge.auxves.dev/arno/ao3-cli:v0.2.2@sha256:ecd57ac619bcb7f14183a512611568291d245639e3236679891953a7b60128b1";

        environment = {
          LOG_LEVEL = "DEBUG";
        };

        environmentFiles = [ config.sops.secrets."ao3/env".path ];

        volumes = [
          "${cfg.volumes.archive.path}:/state"
        ];

        cmd = [ "bookmarks" "sync" "/state" ];
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
