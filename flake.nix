{
  description = "Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    comin.url = "github:nlewo/comin";
    comin.inputs.nixpkgs.follows = "nixpkgs";

    sops.url = "github:Mic92/sops-nix";
    sops.inputs.nixpkgs.follows = "nixpkgs";
    sops.inputs.nixpkgs-stable.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }: {
    lib = import ./lib.nix self;
    hosts = import ./hosts self;

    packages = self.lib.forAllSystems self.lib.buildPackages;
    devShells = self.lib.forAllSystems (import ./shells self);

    overlays = import ./pkgs/overlays.nix self;

    nixosConfigurations = self.lib.buildVariant "nixos";
    darwinConfigurations = self.lib.buildVariant "darwin";

    formatter = self.lib.forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
  };
}
