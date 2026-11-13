{ inputs, self, ... }: {
  flake = {
    lib = inputs.nixpkgs.lib.extend self.overlays.lib;
    overlays = import ../overlays self;
  };
}
