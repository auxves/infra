self@{ inputs, ... }:
final: _:
let
  lib = final;

  overlays = with self.overlays; [ all unstable ];
  pkgsFor = system: import inputs.nixpkgs { inherit system overlays; };

  hostList = builtins.attrValues self.hosts;
in
{
  internal = {
    inherit pkgsFor;

    forAllSystems = lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    prefixAttrs = prefix: lib.mapAttrs'
      (name: value: lib.nameValuePair "${prefix}-${name}" value);

    platformOf = system: builtins.elemAt (lib.splitString "-" system) 1;

    filterHosts = predicate: builtins.filter predicate hostList;

    readModules = dir:
      let
        isValid = name: type: name != "default.nix";
        files = lib.filterAttrs isValid (builtins.readDir dir);
      in
      map (n: dir + "/${n}") (builtins.attrNames files);

    variants = {
      nixos = host: inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self host lib; };
        modules = [
          ../../modules/common ../../modules/${host.variant} ../../hosts/${host.name}
          { nixpkgs.overlays = overlays; }
        ];
      };

      darwin = host: inputs.darwin.lib.darwinSystem {
        specialArgs = { inherit self host lib; };
        modules = [
          ../../modules/common ../../modules/${host.variant} ../../hosts/${host.name}
          { nixpkgs.overlays = overlays; }
        ];
      };
    };

    buildVariant = variant:
      let
        isApplicable = _: host: host.variant == variant;
        hosts = lib.filterAttrs isApplicable self.hosts;
      in
      lib.mapAttrs (_: host: host.configuration) hosts;

    buildPackages = pkgsFor;

    buildChecks = system:
      let
        pkgs = pkgsFor system;
      in
      lib.filterAttrs
        (_: lib.meta.availableOn pkgs.stdenv.hostPlatform)
        pkgs.auxves.checks;

    replaceAll = attrs: builtins.replaceStrings
      (builtins.attrNames attrs)
      (builtins.attrValues attrs);
  };
}
