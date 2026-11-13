{ lib, config, host, pkgs, ... }:
let
  cfg = config.presets.emulation;

  emulatedSystems = lib.remove host.system [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ];

  flags = {
    fixBinary = true;
    matchCredentials = true;
  };

  registrations = builtins.listToAttrs (map (system: lib.nameValuePair system flags) emulatedSystems);
in
{
  options.presets.emulation = with lib; {
    enable = mkEnableOption "Enable emulation";
  };

  config = lib.mkIf cfg.enable {
    boot.binfmt = {
      inherit emulatedSystems registrations;
    };

    environment.systemPackages = with pkgs; [ qemu ];
  };
}
