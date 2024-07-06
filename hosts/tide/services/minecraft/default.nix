{ ... }: {
  disko.devices.zpool.storage.datasets."services/minecraft-vz".type = "zfs_fs";

  virtualisation.oci-containers.containers.minecraft-vz = {
    image = "itzg/minecraft-server:2024.6.1-java21-graalvm@sha256:41f60e34e630e698c39509c291565f1f962788d7628a82f91d932c5c8af3fc1a";
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

      MOTD = "§l§cNo iPhones allowed!§r";
    };

    volumes = [
      "/storage/services/minecraft-vz:/data"
      "${./icon.png}:/data/server-icon.png"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
