{ ... }: {
  flake.modules.homeManager.users-arno = { ... }: {
    home.sessionPath = [
      "$HOME/.local/bin"
    ];

    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };

    home.stateVersion = "23.05";
  };
}
