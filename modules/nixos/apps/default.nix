{ self, lib, config, options, pkgs, ... }:
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

  volumeOptions = { name, appName, config, ... }: {
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
            if appName != name
            then "/var/cache/${appName}-${name}"
            else "/var/cache/${appName}";
          zfs =
            if appName != name
            then "/storage/services/${appName}/${name}"
            else "/storage/services/${appName}";
        }.${config.type};
      };

      acls = mkOption {
        type = types.listOf types.str;
        description = "Additional ACLs to assign to this volume";
        default = [ ];
      };
    };
  };

  ingressOptions = { appName, ... }: {
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
        default = "${appName}.${config.networking.hostName}.x.auxves.dev";
        description = "The domain to use for ingress";
      };
    };
  };

  appOptions = { name, ... }: {
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
          specialArgs = { appName = name; };
        });
        default = { };
        description = "The containers that provide the application";
      };

      volumes = mkOption {
        type = types.attrsOf (types.submoduleWith {
          modules = [ volumeOptions ];
          specialArgs = { appName = name; };
        });
        default = { };
        description = "The volumes to create";
      };

      ingress = mkOption {
        type = types.nullOr (types.submoduleWith {
          modules = [ ingressOptions ];
          specialArgs = { appName = name; };
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
