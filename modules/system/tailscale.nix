{ ... }: {
  flake.modules.nixos.tailscale = { pkgs, ... }: {
    services.tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
