{ self, lib, config, ... }:
let
  cfg = config.presets.gitops;
in
{
  imports = [
    self.inputs.comin.nixosModules.comin
  ];

  options.presets.gitops = with lib; {
    enable = mkEnableOption "Enable GitOps deployments";
  };

  config = lib.mkIf cfg.enable {
    services.comin = {
      enable = true;
      remotes = [{
        name = "origin";
        url = "https://github.com/auxves/infra";
        branches.testing.name = "staging";
      }];
    };

    systemd.services.comin.serviceConfig.LogExtraFields = [ "ALLOY_ENABLE=true" ];

    networking.firewall = {
      interfaces."podman+".allowedTCPPorts = lib.mkIf (config.apps ? alloy) [
        4243 # Metrics port
      ];
    };
  };
}
