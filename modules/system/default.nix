{ inputs, ... }: {
  flake.modules = {
    nixos.default = {
      imports = with inputs.self.modules.nixos; [
        nix
        shell
        ssh

        meta
        monitoring
        apps-framework
      ] ++ [
        inputs.sops.nixosModules.sops
      ];

      environment.defaultPackages = [ ];

      programs.nix-ld.enable = true;
      programs.command-not-found.enable = false;
    };

    darwin.default = { lib, ... }: {
      imports = with inputs.self.modules.darwin; [
        nix
        shell

        meta
        monitoring
      ] ++ [
        inputs.sops.darwinModules.sops
      ];
    };
  };
}
