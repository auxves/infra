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
        image = "ghcr.io/muchobien/pocketbase:0.37.1@sha256:a3099d3f6677f179a679dad297b1d420aa173502cf9b3fed479bf3cfc6e59a04";

        volumes = [
          "${cfg.volumes.pocketbase.path}:/pb_data"
        ];
      };

      archival = {
        autoStart = false;

        image = "forge.auxves.dev/arno/ao3-cli:v0.2.0@sha256:10043c1322c4750297a772488e6f74b27175b1a3a6f2cd3abc644dbad7e92397";

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
