{ inputs, ... }: {
  flake.modules.generic.development = { lib, config, ... }:
    let
      cfg = config.presets.development;
    in
    {
      options.presets.development = with lib; {
        enable = mkEnableOption "Enable development environment";
      };

      config = lib.mkIf cfg.enable {
        presets.home.modules = [{ presets.development.enable = true; }];
      };
    };

  flake.modules.nixos.development = {
    imports = [ inputs.self.modules.generic.development ];
  };

  flake.modules.darwin.development = {
    imports = [ inputs.self.modules.generic.development ];
  };
}
