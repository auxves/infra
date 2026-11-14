{ ... }: {
  flake.modules.nixos.tailscale = { pkgs, ... }: {
    services.tailscale.package = pkgs.unstable.tailscale;
  }
  ;
}
