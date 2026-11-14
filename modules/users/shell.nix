{ inputs, ... }: {
  flake.modules.generic.shell = { pkgs, ... }: {
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

  flake.modules.nixos.shell = {
    imports = [ inputs.self.modules.generic.shell ];
  };

  flake.modules.darwin.shell = {
    imports = [ inputs.self.modules.generic.shell ];
  };
}
