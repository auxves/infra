{ ... }: {
  flake.modules.homeManager.darwin = { lib, pkgs, ... }: {
    config = lib.mkIf pkgs.stdenv.isDarwin {
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
  };
}
