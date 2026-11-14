{ ... }: {
  flake.modules.nixos.system = { lib, pkgs, ... }: {
    nix.settings = {
      experimental-features = [ "cgroups" ];
      use-cgroups = true;
    };

    users.defaultUserShell = pkgs.fish;

    environment.defaultPackages = [ ];

    programs.nix-ld.enable = true;
    programs.command-not-found.enable = false;
  };
}
