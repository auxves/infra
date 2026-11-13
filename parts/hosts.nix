{ self, ... }: {
  flake = {
    hosts = import ../hosts self;

    nixosConfigurations = self.lib.internal.buildVariant "nixos";
    darwinConfigurations = self.lib.internal.buildVariant "darwin";
  };
}
