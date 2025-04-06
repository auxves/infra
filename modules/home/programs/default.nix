{ lib, ... }: {
  imports = lib.internal.readModules ./.;
}
