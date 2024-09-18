{ lib, config, pkgs, ... }:
let
  cfg = config.storage.zfs;
in
{
  options.storage.zfs = with lib; {
    health.enable = mkEnableOption "Enable ZFS health check";
    health.webhook = mkOption {
      type = types.str;
      description = "Uptime Kuma webhook to send status to";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.health.enable {
      systemd.services.zfs-health-check =
        let
          script = pkgs.writeShellApplication {
            name = "zfs-health-check";
            runtimeInputs = with pkgs; [ zfs curl ];
            text = ''
              if [ "$(zpool status -x)" = "all pools are healthy" ]; then
                STATUS=up
                MESSAGE="All pools are healthy"
              else
                STATUS=down
                MESSAGE="One or more pools are degraded"
              fi

              curl --get \
                --data-urlencode "status=$STATUS" \
                --data-urlencode "msg=$MESSAGE" \
                ${cfg.health.webhook}
            '';
          };
        in
        {
          description = "Health check for ZFS pools which reports to Uptime Kuma";
          after = [ "podman-uptime-kuma.service" ];
          startAt = "*:*:00";

          serviceConfig = {
            ExecStart = "${script}/bin/zfs-health-check";
            DynamicUser = "yes";
          };
        };
    })
  ];
}
