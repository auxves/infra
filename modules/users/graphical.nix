{ ... }: {
  flake.modules =
    let
      graphical = { lib, config, ... }:
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
    in
    {
      nixos.graphical = graphical;
      darwin.graphical = graphical;
    };
}
