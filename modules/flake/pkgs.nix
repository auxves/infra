{ inputs, self, ... }: {
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = with self.overlays; [ all unstable ];
      config.allowUnfree = true;
    };
  };
}
