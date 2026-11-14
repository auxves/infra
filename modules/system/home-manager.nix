{ inputs, ... }: {
  flake.modules.nixos.home = { lib, config, ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    config = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    };
  };

  flake.modules.darwin.home = { lib, config, ... }: {
    imports = [
      inputs.home-manager.darwinModules.home-manager
    ];

    config = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    };
  };
}
