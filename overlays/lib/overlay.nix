self:
final: _:
let
  lib = final;

  hostList = builtins.attrValues self.hosts;

  pullableContainer = container:
    container.imageFile == null && container.imageStream == null;

  collectContainerImages = apps: include:
    lib.sort builtins.lessThan (lib.unique (lib.concatMap
      (app: lib.mapAttrsToList
        (_: container: container.image)
        (lib.filterAttrs
          (_: container: pullableContainer container && include container)
          app.containers))
      (builtins.attrValues apps)));
in
{
  internal = {
    prefixAttrs = prefix: lib.mapAttrs'
      (name: value: lib.nameValuePair "${prefix}-${name}" value);

    filterHosts = predicate: builtins.filter predicate hostList;

    readModules = dir:
      let
        isValid = name: type: name != "default.nix";
        files = lib.filterAttrs isValid (builtins.readDir dir);
      in
      map (n: dir + "/${n}") (builtins.attrNames files);

    inherit collectContainerImages;

    containerImagesForHost = host: collectContainerImages host.cfg.apps (_: true);

    replaceAll = attrs: builtins.replaceStrings
      (builtins.attrNames attrs)
      (builtins.attrValues attrs);
  };
}
