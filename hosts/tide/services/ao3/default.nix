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
        image = "ghcr.io/muchobien/pocketbase:0.40.6@sha256:9a0be68a80ca1348ba8d15f217b3f983be4c094b3c571a09b3ebdeb357259338";

        volumes = [
          "${cfg.volumes.pocketbase.path}:/pb_data"
        ];
      };

      archival = {
        autoStart = false;

        image = "forge.auxves.dev/arno/ao3-cli:v0.2.6@sha256:3bbbfd178b4e46a15046d7a0873ae48977992bf6aaa072ff040d19c6b3396597";

        environment = {
          LOG_LEVEL = "DEBUG";
          AO3_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5.2 Safari/605.1.15";
        };

        environmentFiles = [ config.sops.secrets."ao3/env".path ];

        volumes = [
          "${cfg.volumes.archive.path}:/state"
        ];

        cmd = [ "bookmarks" "sync" "/state" ];

        service = {
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
