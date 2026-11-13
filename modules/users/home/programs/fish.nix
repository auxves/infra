{ config, lib, ... }: {
  config = lib.mkIf config.programs.fish.enable {
    programs.fish = {
      interactiveShellInit = ''
        set fish_greeting
      '';
    };
  };
}
