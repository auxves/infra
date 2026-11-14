{ ... }:
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
  flake.modules.nixos.shell = { pkgs, ... }: {
    imports = [ shell ];
    users.defaultUserShell = pkgs.fish;
  };

  flake.modules.darwin.shell = {
    imports = [ shell ];
  };
}
