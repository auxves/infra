{ lib, config, ... }:
let
  processContainer = app: _: container:
    let
      ingresses = lib.filterAttrs (_: ingress: ingress.container == container.name) app.ingresses;

      traefikLabels = lib.concatMapAttrs
        (_: ingress:
          let
            router = "${app.name}-${ingress.name}";
          in
          {
            "traefik.http.routers.${router}.rule" = ingress.rule;
            "traefik.http.routers.${router}.entrypoints" = ingress.type;
            "traefik.http.services.${router}.loadbalancer.server.port" = toString ingress.port;
          })
        ingresses;

      changes = {
        serviceName = "podman-${container.fullName}";

        labels = {
          "app.service" = app.name;
          "app.component" = container.name;
          "app.node" = config.networking.hostName;
        } // traefikLabels // lib.optionalAttrs (traefikLabels != { }) {
          "traefik.enable" = "true";
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
    presets.containers.enable = true;

    virtualisation.oci-containers.containers = lib.foldl' lib.recursiveUpdate { } containers;
  };
}
