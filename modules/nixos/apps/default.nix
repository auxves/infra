{ self, lib, config, options, pkgs, ... }:
let
  osConfig = config;

  metricsOptions = { app, ... }: {
    options = with lib; {
      job = mkOption {
        type = types.str;
        default = app.name;
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

  containerOptions = { name, app, ... }: {
    options = with lib; builtins.removeAttrs
      (options.virtualisation.oci-containers.containers.type.getSubOptions [ ])
      [ "_module" ] // {
      name = mkOption {
        type = types.str;
        default = name;
        readOnly = true;
        description = "The name of the container";
      };

      fullName = mkOption {
        type = types.str;
        default = if name == app.name then app.name else "${app.name}-${name}";
        readOnly = true;
        description = "The full name of the container as seen by podman";
      };

      metrics = mkOption {
        type = types.nullOr (types.submoduleWith {
          modules = [ metricsOptions ];
          specialArgs = { inherit app; };
        });
        default = null;
        description = "Metrics options for the container";
      };
    };
  };

  volumeOptions = { name, app, config, ... }: {
    options = with lib; {
      name = mkOption {
        type = types.str;
        default = name;
        readOnly = true;
        description = "The name of the volume";
      };

      type = mkOption {
        type = types.enum [ "ephemeral" "zfs" ];
        default = "ephemeral";
      };

      path = mkOption {
        type = types.str;
        description = "The filesystem path to this volume";
        default = {
          ephemeral =
            if app.name != name
            then "/var/cache/${app.name}-${name}"
            else "/var/cache/${app.name}";
          zfs =
            if app.name != name
            then "/storage/services/${app.name}/${name}"
            else "/storage/services/${app.name}";
        }.${config.type};
      };

      acls = mkOption {
        type = types.listOf types.str;
        description = "Additional ACLs to assign to this volume";
        default = [ ];
      };
    };
  };

  ingressOptions = { config, app, ... }: {
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

      domain = mkOption {
        type = types.str;
        default = "${app.name}.${osConfig.networking.hostName}.x.auxves.dev";
        description = "The domain to use for ingress";
      };

      rule = mkOption {
        type = types.str;
        default = "Host(`${config.domain}`)";
        description = "The traefik rule to use for this ingress";
      };
    };
  };

  appOptions = { config, name, ... }: {
    imports = [ ./presets ];

    options = with lib; {
      name = mkOption {
        type = types.str;
        default = name;
        readOnly = true;
        description = "The name of the application";
      };

      containers = mkOption {
        type = types.attrsOf (types.submoduleWith {
          modules = [ containerOptions ];
          specialArgs = { app = config; };
        });
        default = { };
        description = "The containers that provide the application";
      };

      volumes = mkOption {
        type = types.attrsOf (types.submoduleWith {
          modules = [ volumeOptions ];
          specialArgs = { app = config; };
        });
        default = { };
        description = "The volumes to create";
      };

      ingress = mkOption {
        type = types.nullOr (types.submoduleWith {
          modules = [ ingressOptions ];
          specialArgs = { app = config; };
        });
        default = null;
        description = "Ingress options for the application";
      };
    };
  };

in
{
  imports = [ ./containers.nix ./volumes.nix ];

  options = with lib; {
    apps = mkOption {
      default = { };
      type = types.attrsOf (types.submoduleWith {
        modules = [ appOptions ];
        specialArgs = {
          inherit self lib pkgs;
          osConfig = config;
        };
      });
      description = "Applications to host on this node";
    };
  };
}
