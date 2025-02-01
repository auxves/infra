{ lib, config, ... }:
let
  processContainer = app: containerName: container:
    let
      name =
        if app.name != containerName
        then "${app.name}-${containerName}"
        else app.name;

      changes = {
        serviceName = "podman-${name}";

        labels = {
          "app.service" = app.name;
          "app.component" = containerName;
          "app.node" = config.networking.hostName;
        } // lib.optionalAttrs (app.ingress != null && app.ingress.container == containerName) {
          "traefik.enable" = "true";
          "traefik.http.routers.${app.name}.rule" = "Host(`${app.ingress.host}`)";
          "traefik.http.routers.${app.name}.entrypoints" = app.ingress.type;
          "traefik.http.services.${app.name}.loadbalancer.server.port" = toString app.ingress.port;
        } // lib.optionalAttrs (container.metrics != null) {
          "metrics.enable" = "true";
          "metrics.job" = if container.metrics.job != "" then container.metrics.job else app.name;
          "metrics.path" = container.metrics.path;
          "metrics.scheme" = container.metrics.scheme;
          "metrics.port" = toString container.metrics.port;
        };
      };
    in
    lib.nameValuePair name (builtins.removeAttrs (lib.recursiveUpdate container changes) [ "metrics" ]);

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

    virtualisation.oci-containers.containers = lib.foldl' lib.recursiveUpdate { } containers;
  };
}
