self @ { lib, inputs, ... }:
let
  overlays = with self.overlays; [ all unstable ];
  pkgsFor = system: import inputs.nixpkgs { inherit system overlays; };

  hostList = builtins.attrValues self.hosts;
in
inputs.nixpkgs.lib.extend (_: _: {
  inherit pkgsFor;

  forAllSystems = lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

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
        ./modules/common ./modules/${host.variant} ./hosts/${host.name}
        { nixpkgs.pkgs = pkgsFor host.system; }
      ];
    };

    darwin = host: inputs.darwin.lib.darwinSystem {
      specialArgs = { inherit self host lib; };
      modules = [
        ./modules/common ./modules/${host.variant} ./hosts/${host.name}
        { nixpkgs.pkgs = pkgsFor host.system; }
      ];
    };
  };

  buildVariant = variant:
    let
      isApplicable = _: host: host.variant == variant;
      hosts = lib.filterAttrs isApplicable self.hosts;
    in
    lib.mapAttrs (_: host: host.configuration) hosts;

  buildPackages = system:
    let
      final = pkgsFor system;
      prev = import inputs.nixpkgs { inherit system; };
    in
    self.overlays.default final prev;

  replaceAll = attrs: builtins.replaceStrings
    (builtins.attrNames attrs)
    (builtins.attrValues attrs);

  ingressesOfHost = host: lib.mapAttrsToList
    (_: app: app.ingress // { inherit host; })
    (lib.filterAttrs (_: app: app.ingress != null) host.cfg.apps);
})
