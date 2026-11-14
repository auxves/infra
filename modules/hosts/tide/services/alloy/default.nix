{ inputs, ... }: {
  flake.modules.nixos.tide = {
    imports = with inputs.self.modules.nixos; [
      alloy
      exporters
    ];
  };
}
