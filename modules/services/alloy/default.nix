{ inputs, ... }: {
  flake.modules.nixos.tide = {
    imports = [ inputs.self.modules.nixos.alloy ];
  };

  flake.modules.nixos.harpy = {
    imports = [ inputs.self.modules.nixos.alloy ];
  };
}
