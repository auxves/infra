{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.programs.nushell.enable {
    programs.nushell = {
      package = pkgs.unstable.nushell;
      configFile.text = ''
        $env.config.show_banner = false
      '';
    };
  };
}
