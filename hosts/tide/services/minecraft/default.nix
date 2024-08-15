{ config, ... }:
let
  paths = config.storage.paths;
in
{
  storage.paths."services/minecraft-vz" = { };

  virtualisation.oci-containers.containers.minecraft-vz = {
    image = "itzg/minecraft-server:2024.7.2-java21-graalvm@sha256:9944796b60e917ee4dc51685b52165adadcc6f501fdb647015879146e1f6312c";
    autoStart = false;

    ports = [ "25565:25565" "[::]:25565:25565" ];

    environment = {
      EULA = "true";
      MEMORY = "8G";
      SEED = "-1254774536";
      USE_AIKAR_FLAGS = "true";
      USE_SIMD_FLAGS = "true";
      MOD_PLATFORM = "MODRINTH";
      MODRINTH_MODPACK = "/mods.mrpack";

      MOTD = "No iPhones allowed!";
      SPAWN_PROTECTION = "0";
      ENABLE_COMMAND_BLOCK = "true";
    };

    volumes = [
      "${paths."services/minecraft-vz".path}:/data"
      "${./icon.png}:/data/server-icon.png"
      "${./vz.mrpack}:/mods.mrpack:ro"
      "/etc/localtime:/etc/localtime:ro"
    ];
  };

  systemd.services.podman-minecraft-vz = {
    stopIfChanged = false;
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
