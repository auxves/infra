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
      TYPE = "FABRIC";
      USE_AIKAR_FLAGS = "true";
      USE_SIMD_FLAGS = "true";
      VERSION = "1.20.1";

      MOTD = "No iPhones allowed!";
    };

    volumes = [
      "${paths."services/minecraft-vz".path}:/data"
      "${./icon.png}:/data/server-icon.png"
      "/etc/localtime:/etc/localtime:ro"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
