{ lib, config, pkgs, ... }:
let
  cfg = config.presets.development;
in
{
  options.presets.development = with lib; {
    enable = mkEnableOption "Enable development environment";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      skim
      jq

      # Zig
      zig
      zls

      # Nix
      nil
      nixpkgs-fmt

      # JS
      bun
      nodejs_20

      # Rust
      fenix.latest.toolchain

      # Containers
      docker-client
      docker-credential-helpers
      podman

      # Man
      man-pages
      man-pages-posix
    ];

    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };

    home.sessionVariables = {
      CARGO_HOME = "${config.xdg.cacheHome}/cargo";
      GRADLE_USER_HOME = "${config.xdg.cacheHome}/gradle";
    };
  };
}
