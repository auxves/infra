{ ... }: {
  flake.modules.homeManager.darwin-defaults = { ... }: {
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
