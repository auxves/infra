{ ... }: {
  flake.modules.homeManager.users-arno = {
    programs.fish = {
      enable = true;

      interactiveShellInit = ''
        set fish_greeting
      '';
    };
  };
}
