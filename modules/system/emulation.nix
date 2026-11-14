{ ... }: {
  flake.modules.nixos.emulation = { lib, config, pkgs, ... }:
    let
      emulatedSystems = lib.remove config.nixpkgs.hostPlatform.system [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ];

      flags = {
        fixBinary = true;
        matchCredentials = true;
      };

      registrations = builtins.listToAttrs (map (system: lib.nameValuePair system flags) emulatedSystems);
    in
    {
      boot.binfmt = {
        inherit emulatedSystems registrations;
      };

      environment.systemPackages = with pkgs; [ qemu ];
    };
}
