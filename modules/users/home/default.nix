{ inputs, ... }: {
  flake.modules.homeManager.home = {
    imports = with inputs.self.modules.homeManager; [
      darwin
      fish
      git
      nushell
      skhd
      yabai
      zoxide
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
    };

    home.sessionPath = [
      "$HOME/.local/bin"
    ];

    programs.fish.enable = true;
    programs.nushell.enable = true;
    programs.git.enable = true;
    programs.zoxide.enable = true;

    home.stateVersion = "23.05";
  };
}
