{ lib, config, ... }:
let
  processContainer = app: _: container:
    let
      changes = {
        serviceName = "podman-${container.fullName}";

        labels = {
          "app.service" = app.name;
          "app.component" = container.name;
          "app.node" = config.networking.hostName;
        } // lib.optionalAttrs (app.ingress != null && app.ingress.container == container.name) {
          "traefik.enable" = "true";
          "traefik.http.routers.${app.name}.rule" = app.ingress.rule;
          "traefik.http.routers.${app.name}.entrypoints" = app.ingress.type;
          "traefik.http.services.${app.name}.loadbalancer.server.port" = toString app.ingress.port;
        } // lib.optionalAttrs (container.metrics != null) {
          "metrics.enable" = "true";
          "metrics.job" = container.metrics.job;
          "metrics.path" = container.metrics.path;
          "metrics.scheme" = container.metrics.scheme;
          "metrics.port" = toString container.metrics.port;
        };
      };
    in
    lib.nameValuePair container.fullName (builtins.removeAttrs (lib.recursiveUpdate container changes) [
      "name"
      "fullName"
      "metrics"
    ]);

  containers = lib.mapAttrsToList processContainers config.apps;

  processContainers = _: app: lib.mapAttrs'
    (processContainer app)
    app.containers;
in
{
  config = lib.mkIf (config.apps != { }) {
    assertions = builtins.concatLists (lib.mapAttrsToList
      (_: app: [
        {
          assertion = app.ingress != null -> app.containers ? "${app.ingress.container}";
          message = "Ingress must point to a valid container";
        }
      ])
      config.apps);

    presets.containers.enable = true;

    virtualisation.oci-containers.containers = lib.foldl' lib.recursiveUpdate { } containers;
  };
}
