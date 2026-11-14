{ inputs, ... }: {
  flake.modules.darwin.blaze = { config, ... }: {
    imports = with inputs.self.modules.darwin; [ default home ];

    networking.hostName = "blaze";

    home-manager.users.${config.home.user}.imports = with inputs.self.modules.homeManager; [
      development
      graphical
    ];

    builders.outsource = true;
  };
}
