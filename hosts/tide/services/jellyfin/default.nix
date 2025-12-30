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
        image = "jellyfin/jellyfin:10.11.5@sha256:6d819e9ab067efcf712993b23455cc100ee5585919bb297ea5a109ac00cb626e";

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
