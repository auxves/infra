{ lib, config, options, ... }:
let
  metricsOptions = {
    options = with lib; {
      job = mkOption {
        type = types.str;
        default = "";
        description = "The name of this scraping job";
      };

      path = mkOption {
        type = types.str;
        default = "/metrics";
        description = "The path to scrape metrics from";
      };

      port = mkOption {
        type = types.port;
        description = "The container port to use for ingress";
      };

      scheme = mkOption {
        type = types.str;
        default = "http";
        description = "The scheme to use for scraping";
      };
    };
  };

  containerOptions = {
    options = with lib; builtins.removeAttrs
      (options.virtualisation.oci-containers.containers.type.getSubOptions [ ])
      [ "_module" ] // {
      metrics = mkOption {
        type = types.nullOr (types.submodule metricsOptions);
        default = null;
        description = "Metrics options for the container";
      };
    };
  };

  ingressOptions = {
    options = with lib; {
      type = mkOption {
        type = types.enum [ "internal" "public" ];
        default = "internal";
        description = "The access level to this ingress";
      };

      container = mkOption {
        type = types.str;
        description = "The container to use for ingress";
      };

      port = mkOption {
        type = types.port;
        description = "The container port to use for ingress";
      };

      host = mkOption {
        type = types.str;
        description = "The hostname to use for ingress";
      };
    };
  };

  appOptions = { name, ... }: {
    options = with lib; {
      name = mkOption {
        type = types.str;
        default = name;
        readOnly = true;
        description = "The name of the application";
      };

      containers = mkOption {
        type = types.attrsOf (types.submodule containerOptions);
        default = { };
        description = "The containers that provide the application";
      };

      ingress = mkOption {
        type = types.nullOr (types.submodule ingressOptions);
        default = null;
        description = "Ingress options for the application";
      };
    };
  };

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

  processContainers = _: app: lib.mapAttrs'
    (processContainer app)
    app.containers;
in
{
  options = with lib; {
    apps = mkOption {
      default = { };
      type = types.attrsOf (types.submodule appOptions);
      description = "Applications to host on this node";
    };
  };

  config = lib.mkIf (config.apps != { }) {
    virtualisation.oci-containers.containers = lib.foldl' lib.recursiveUpdate { }
      (lib.mapAttrsToList processContainers config.apps);
  };
}
