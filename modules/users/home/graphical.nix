{ ... }: {
  flake.modules.homeManager.graphical = { lib, pkgs, ... }: {
    config = lib.mkMerge [
      {
        home.packages = with pkgs; [
          # Fonts
          inter
          fira-code
        ];

        fonts.fontconfig.enable = true;
      }

      (lib.mkIf pkgs.stdenv.isDarwin {
        services.yabai.enable = true;
        services.skhd.enable = true;
      })
    ];
  };
}
