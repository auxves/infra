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
    ];

    programs.git.enable = true;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.sessionVariables = {
      DIRENV_LOG_FORMAT = "";

      CARGO_HOME = "${config.xdg.cacheHome}/cargo";
      GRADLE_USER_HOME = "${config.xdg.cacheHome}/gradle";
    };
  };
}
