{ lib, config, pkgs, host, ... }:
let
  cfg = config.services.zfs;
in
{
  options.services.zfs = with lib; {
    health.enable = mkEnableOption "Enable ZFS health check";
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
                SUCCESS=true
              else
                SUCCESS=false
              fi

              curl -X POST --get \
                --data-urlencode "success=$SUCCESS" \
                --data-urlencode "error=$(zpool status -x)" \
                --header "Authorization: Bearer ${host.name}" \
                https://status.x.auxves.dev/api/v1/endpoints/zfs_${host.name}/external
            '';
          };
        in
        {
          description = "Health check for ZFS pools which reports to Gatus";
          startAt = "*:*:00";

          serviceConfig = {
            ExecStart = "${script}/bin/zfs-health-check";
            DynamicUser = "yes";
          };
        };

      monitoring.endpoints = [{
        name = host.name;
        group = "zfs";
        token = host.name;
        alerts = [{ type = "discord"; }];
      }];
    })
  ];
}
