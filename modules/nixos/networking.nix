{ pkgs, ... }: {
  services.tailscale.package = pkgs.unstable.tailscale;
}
