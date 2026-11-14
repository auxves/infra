{ ... }: {
  flake.modules =
    let
      shell = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          curl
          neovim
          tmux
        ];

        programs.fish = {
          enable = true;
          useBabelfish = true;
        };

        environment.shells = with pkgs; [ fish ];
      };
    in
    {
      nixos.shell = shell;
      darwin.shell = shell;
    };
}
