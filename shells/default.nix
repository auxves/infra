{ lib, ... }:
lib.internal.forAllSystems (system:
let
  pkgs = lib.internal.pkgsFor system;
in
{
  default = pkgs.callPackage ./default { };
})
