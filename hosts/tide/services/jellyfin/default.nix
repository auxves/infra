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
    };

    containers = {
      jellyfin = {
        image = "jellyfin/jellyfin:10.10.7@sha256:7ae36aab93ef9b6aaff02b37f8bb23df84bb2d7a3f6054ec8fc466072a648ce2";

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
