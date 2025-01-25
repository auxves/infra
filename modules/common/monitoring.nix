{ lib, ... }: {
  options.monitoring = with lib; {
    checks = mkOption {
      type = types.listOf types.attrs;
      description = "Endpoints to be checked periodically by Gatus";
      default = [ ];
    };

    endpoints = mkOption {
      type = types.listOf types.attrs;
      description = "Endpoints that are pushed using the Gatus API";
      default = [ ];
    };
  };
}
