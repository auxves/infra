{ inputs, ... }: {
  flake.modules.nixos.gitops = { lib, config, ... }: {
    imports = [
      inputs.comin.nixosModules.comin
    ];

    config = {
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
  };
}
