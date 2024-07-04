{ ... }: {
  disko.devices.zpool.storage.datasets."services/minecraft-vz".type = "zfs_fs";

  virtualisation.oci-containers.containers.minecraft-vz = {
    image = "itzg/minecraft-server:2024.6.1-java21-graalvm@sha256:41f60e34e630e698c39509c291565f1f962788d7628a82f91d932c5c8af3fc1a";
    autoStart = false;

    ports = [ "25565:25565" "[::]:25565:25565" ];

    environment = {
      EULA = "true";
      MEMORY = "8G";
      SEED = "gi//2WUWTxu6XfdK";
      TYPE = "FABRIC";
      USE_AIKAR_FLAGS = "true";
      USE_SIMD_FLAGS = "true";
      VERSION = "1.20.4";
    };

    volumes = [ "/storage/services/minecraft-vz:/data" ];
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
