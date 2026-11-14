{ inputs, lib, self, ... }: {
  flake.lib = (inputs.nixpkgs.lib.extend self.overlays.lib) // {
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
          { nixpkgs.overlays = with inputs.self.overlays; [ all unstable ]; }
        ];
      };
    };

    mkDarwin = system: name: {
      ${name} = inputs.darwin.lib.darwinSystem {
        modules = [
          inputs.self.modules.darwin.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
          { nixpkgs.overlays = with inputs.self.overlays; [ all unstable ]; }
        ];
      };
    };
  };

  flake.overlays = import ../../overlays self;
}
