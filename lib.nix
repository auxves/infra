self @ { lib, inputs, ... }:
let
  overlays = [ self.overlays.all ];
  pkgsFor = system: import inputs.nixpkgs { inherit system overlays; };

  hostList = builtins.attrValues self.hosts;

  buildWith = builder: host: builder {
    pkgs = pkgsFor host.system;
    specialArgs = { inherit self host lib; };
    modules = [ ./modules ./modules/${host.variant} ./hosts/${host.name} ];
  };
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

  filterHostsOf = variants: predicate: builtins.filter
    (host: builtins.elem host.variant variants && predicate host)
    hostList;

  readModules = dir:
    let
      isValid = name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";
      files = lib.filterAttrs isValid (builtins.readDir dir);
    in
    map (n: dir + "/${n}") (builtins.attrNames files);

  variants = {
    nixos = buildWith inputs.nixpkgs.lib.nixosSystem;
    darwin = buildWith inputs.darwin.lib.darwinSystem;
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
    self.overlays.export final prev;
})
