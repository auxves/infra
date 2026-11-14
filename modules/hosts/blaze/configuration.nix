{ inputs, ... }: {
  flake.modules.darwin.blaze = { config, ... }: {
    imports = with inputs.self.modules.darwin; [
      default

      builders-client
      users-arno
    ];

    home-manager.users.arno.imports = [
      inputs.self.modules.homeManager.blaze
    ];

    security.pam.services.sudo_local.touchIdAuth = true;

    system.stateVersion = 4;
  };

  flake.modules.homeManager.blaze = { pkgs, config, ... }: {
    imports = with inputs.self.modules.homeManager; [
      yabai
      skhd
    ];

    home.packages = with pkgs; [
      skim
      jq

      # Nix
      nil
      nixpkgs-fmt

      # JS
      bun
      nodejs_24

      # Python
      python3
      unstable.uv

      # Rust
      fenix.latest.toolchain

      # Containers
      docker-client
      docker-credential-helpers
      podman

      # Man
      man-pages
      man-pages-posix

      # Fonts
      inter
      fira-code
    ];

    home.sessionVariables = {
      CARGO_HOME = "${config.xdg.cacheHome}/cargo";
      GRADLE_USER_HOME = "${config.xdg.cacheHome}/gradle";
    };

    fonts.fontconfig.enable = true;

    targets.darwin.defaults = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      "com.apple.dock" = {
        autohide = true;
        "autohide-delay" = 0;
        "autohide-time-modifier" = 0.3;
      };
    };
  };
}
