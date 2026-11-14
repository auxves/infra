{ ... }: {
  flake.modules.homeManager.users-arno = { pkgs, ... }: {
    home.packages = [ pkgs.neovim ];

    home.sessionVariables = {
      EDITOR = "nvim";
    };
  };
}
