{ inputs, ... }: {
  flake.modules.nixos.harpy = {
    imports = with inputs.self.modules.nixos; [
      alloy
      exporters
    ];
  };
}
