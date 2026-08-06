{
  description = "Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    fenix.url = "github:nix-community/fenix/monthly";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    # Custom branch to support comin
    lanzaboote.url = "github:nix-community/lanzaboote/5db662a929bed2a9c7b0ea0f7b946156e077bdca";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/v1.13.0";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    comin.url = "github:nlewo/comin/v0.14.0";
    comin.inputs.nixpkgs.follows = "nixpkgs";

    sops.url = "github:Mic92/sops-nix";
    sops.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }:
    let
      lib' = self.lib.internal;
    in
    {
      lib = nixpkgs.lib.extend self.overlays.lib;
      hosts = import ./hosts self;

      legacyPackages = lib'.forAllSystems lib'.buildPackages;
      checks = lib'.forAllSystems lib'.buildChecks;
      devShells = import ./shells self;
      overlays = import ./overlays self;

      nixosConfigurations = lib'.buildVariant "nixos";
      darwinConfigurations = lib'.buildVariant "darwin";
    };
}
