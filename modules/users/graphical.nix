{ inputs, ... }: {
  flake.modules.generic.graphical = { lib, config, ... }:
    let
      cfg = config.presets.graphical;
    in
    {
      options.presets.graphical = with lib; {
        enable = mkEnableOption "Enable graphical environment";
      };

      config = lib.mkIf cfg.enable {
        presets.home.modules = [{ presets.graphical.enable = true; }];
      };
    };

  flake.modules.nixos.graphical = {
    imports = [ inputs.self.modules.generic.graphical ];
  };

  flake.modules.darwin.graphical = {
    imports = [ inputs.self.modules.generic.graphical ];
  };
}
