{ inputs, ... }: {
  flake.modules.nixos.tide = {
    imports = with inputs.self.modules.nixos; [
      alloy
      exporters
    ];
  };

  flake.modules.nixos.harpy = {
    imports = with inputs.self.modules.nixos; [
      alloy
      exporters
    ];
  };
}
