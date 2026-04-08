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
        image = "jellyfin/jellyfin:10.11.8@sha256:1694ff069f0c9dafb283c36765175606866769f5d72f2ed56b6a0f1be922fc37";

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
