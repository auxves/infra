{ config, pkgs, ... }:
let
  cfg = config.apps.jellyfin;
in
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt
    ];
  };

  apps.jellyfin = {
    volumes = {
      jellyfin = { type = "zfs"; };
      library = { type = "zfs"; path = "/storage/media"; };

      videos = { type = "zfs"; path = "/storage/media/videos"; };
    };

    containers = {
      jellyfin = {
        image = "jellyfin/jellyfin:10.11.0@sha256:59417f441213e236a9f907d4e71a13472042409d85f9e9310dbdd87ee33d7bd4";

        volumes = [
          "${cfg.volumes.jellyfin.path}:/config"
          "${cfg.volumes.library.path}:/data/library"
          "${config.apps.riven.volumes.rd.path}:/data/rd:rshared"
        ];

        extraOptions = [
          "--device=/dev/dri"
          "--health-cmd=none"
        ];

        environment = {
          JELLYFIN_PublishedServerUrl = "https://${cfg.ingresses.app.domain}";
        };

        dependsOn = [ config.apps.riven.containers.rclone.fullName ];
      };
    };

    ingresses = {
      app = {
        domain = "jellyfin.auxves.dev";
        container = "jellyfin";
        port = 8096;
      };
    };
  };

  monitoring.checks = [{
    name = "jellyfin";
    group = "services";
    url = "https://${cfg.ingresses.app.domain}";
    interval = "1m";
    alerts = [{ type = "discord"; }];
    conditions = [
      "[STATUS] == 200"
    ];
  }];
}
