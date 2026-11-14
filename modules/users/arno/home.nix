{ inputs, ... }: {
  flake.modules.homeManager.users-arno = { ... }: {
    imports = with inputs.self.modules.homeManager; [
      fish
      git
      neovim
      zoxide
    ];

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
