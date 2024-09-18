{ lib, ... }: {
  imports = lib.readModules ./.;

  options.storage = with lib; {
    enable = mkEnableOption "Enable storage system";
  };
}
