{ config, lib, ... }: {
  config = lib.mkIf config.programs.nushell.enable {
    programs.nushell = {
      configFile.text = ''
        $env.config.show_banner = false
      '';
    };
  };
}
