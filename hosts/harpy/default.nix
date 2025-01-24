{ self, ... }: {
  imports = [
    self.inputs.comin.nixosModules.comin
    self.inputs.sops.nixosModules.sops
    ./hardware.nix
    ./services
  ];

  presets = {
    containers.enable = true;
  };

  storage = {
    enable = true;
  };

  networking.hostId = "c2079aa6";

  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/auxves/infra";
    }];
  };

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };
}
