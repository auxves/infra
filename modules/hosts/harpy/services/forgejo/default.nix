{ inputs, ... }: {
  flake.modules.nixos.harpy = {
    imports = [ inputs.self.modules.nixos.forgejo-runner ];
  };
}
