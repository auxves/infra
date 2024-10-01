{
  description = "Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    lix.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
    lix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    fenix.url = "github:nix-community/fenix/monthly";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/v1.7.0";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    comin.url = "github:nlewo/comin/v0.2.0";
    comin.inputs.nixpkgs.follows = "nixpkgs";

    sops.url = "github:Mic92/sops-nix";
    sops.inputs.nixpkgs.follows = "nixpkgs";
    sops.inputs.nixpkgs-stable.follows = "nixpkgs";
  };

  outputs = { self, ... }: {
    lib = import ./lib.nix self;
    hosts = import ./hosts self;

    packages = self.lib.forAllSystems self.lib.buildPackages;
    devShells = self.lib.forAllSystems (import ./shells self);

    overlays = import ./pkgs/overlays.nix self;

    nixosConfigurations = self.lib.buildVariant "nixos";
    darwinConfigurations = self.lib.buildVariant "darwin";
  };
}
