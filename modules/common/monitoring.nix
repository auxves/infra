{ lib, ... }: {
  options.monitoring = with lib; {
    endpoints = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
    };
  };
}
