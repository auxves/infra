{ ... }: {
  flake.modules.homeManager.users-arno = {
    programs.zoxide.enable = true;

    home.shellAliases = {
      cd = "z";
    };
  };
}
