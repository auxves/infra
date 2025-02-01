{ lib, config, ... }:
let
  cfg = config.presets.containers;
in
{
  options.presets.containers = with lib; {
    enable = mkEnableOption "Enable containerization support";
  };

  config = lib.mkIf cfg.enable {
    users.users.services = {
      uid = 508;
      group = "services";
    };

    users.groups.services = {
      gid = 508;
    };

    networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;

      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };

      defaultNetwork.settings = {
        dns_enabled = true;
        ipv6_enabled = true;

        subnets = [
          { gateway = "10.88.0.1"; subnet = "10.88.0.0/16"; }
          { gateway = "fd80::1"; subnet = "fd80::/64"; }
        ];
      };
    };
  };
}
