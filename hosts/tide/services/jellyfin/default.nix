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
        image = "jellyfin/jellyfin:10.10.6@sha256:96b09723b22fdde74283274bdc1f63b9b76768afd6045dd80d4a4559fc4bb7f3";

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
          JELLYFIN_PublishedServerUrl = "https://${cfg.ingress.domain}";
        };
      };
    };

    ingress = {
      container = "jellyfin";
      domain = "jellyfin.auxves.dev";
      port = 8096;
    };
  };
}
