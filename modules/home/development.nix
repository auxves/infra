{ lib, config, pkgs, ... }:
let
  cfg = config.modules.development;

  rust-toolchain = with pkgs.fenix; combine [
    latest.toolchain
    # targets.x86_64-apple-darwin.latest.rust-std
    # targets.aarch64-apple-darwin.latest.rust-std
    # targets.x86_64-unknown-linux-gnu.latest.rust-std
    # targets.aarch64-unknown-linux-gnu.latest.rust-std
    # targets.x86_64-pc-windows-gnu.latest.rust-std
    # targets.wasm32-unknown-unknown.latest.rust-std
    # targets.wasm32-wasi.latest.rust-std
  ];
in
{
  options.modules.development = with lib; {
    enable = mkEnableOption "Enable development environment";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      delta
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
      rust-toolchain

      # Containers
      docker-client
      docker-credential-helpers

      # Kubernetes
      kubectl
      kubernetes-helm
    ];

    programs.git = let cfg = import ../../config/git.nix; in {
      enable = true;
      userName = cfg.name;
      userEmail = cfg.email;
      extraConfig = cfg.config;
      ignores = cfg.ignores;
    };

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
