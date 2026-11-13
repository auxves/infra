self@{ inputs, ... }:
final: _:
let
  lib = final;

  overlays = with self.overlays; [ all unstable ];

  hostList = builtins.attrValues self.hosts;

  pullableContainer = container:
    container.imageFile == null && container.imageStream == null;

  collectContainerImages = host: include:
    lib.sort builtins.lessThan (lib.unique (lib.concatMap
      (app: lib.mapAttrsToList
        (_: container: container.image)
        (lib.filterAttrs
          (_: container: pullableContainer container && include container)
          app.containers))
      (builtins.attrValues host.cfg.apps)));
in
{
  internal = {
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
          ../../modules/system
          ../../modules/system/nixos.nix
          ../../modules/system/emulation.nix
          ../../modules/system/gitops.nix
          ../../modules/users
          ../../modules/networking
          ../../modules/observability
          ../../modules/services
          ../../modules/security
          ../../hosts/${host.name}
          { nixpkgs.overlays = overlays; }
        ];
      };

      darwin = host: inputs.darwin.lib.darwinSystem {
        specialArgs = { inherit self host lib; };
        modules = [
          ../../modules/system
          ../../modules/system/darwin.nix
          ../../modules/users
          ../../modules/users/darwin.nix
          ../../hosts/${host.name}
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

    inherit collectContainerImages;

    containerImagesForHost = host: collectContainerImages host (_: true);

    replaceAll = attrs: builtins.replaceStrings
      (builtins.attrNames attrs)
      (builtins.attrValues attrs);
  };
}
