{ config, lib, ... }: {
  config = lib.mkIf config.programs.zoxide.enable {
    home.shellAliases = {
      cd = "z";
    };
  };
}
