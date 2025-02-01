{ config, ... }:
let
  cfg = config.apps.minecraft;
in
{
  apps.minecraft = {
    volumes = {
      vz = { type = "zfs"; };
    };

    containers = {
      vz = {
        image = "itzg/minecraft-server:2024.7.2-java21-graalvm@sha256:9944796b60e917ee4dc51685b52165adadcc6f501fdb647015879146e1f6312c";
        autoStart = false;

        ports = [ "25565:25565" "[::]:25565:25565" ];

        environment = {
          EULA = "true";
          MEMORY = "8G";
          SEED = "-1254774536";
          USE_AIKAR_FLAGS = "true";
          USE_SIMD_FLAGS = "true";
          TZ = "America/Los_Angeles";
          MOD_PLATFORM = "MODRINTH";
          MODRINTH_MODPACK = "/mods.mrpack";

          MOTD = "No iPhones allowed!";
          SPAWN_PROTECTION = "0";
          ENABLE_COMMAND_BLOCK = "true";
        };

        volumes = [
          "${cfg.volumes.vz.path}:/data"
          "${./icon.png}:/data/server-icon.png"
          "${./vz.mrpack}:/mods.mrpack:ro"
        ];

        metrics.port = 25585;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
