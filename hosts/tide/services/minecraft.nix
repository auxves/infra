{ ... }: {
  disko.devices.zpool.storage.datasets."services/minecraft-vz".type = "zfs_fs";

  virtualisation.oci-containers.containers.minecraft-vz = {
    image = "itzg/minecraft-server:java21-graalvm@sha256:2ed613b1a5752a6a55132e3ed447e74994c6a3aeeaf9ee6ffbd2e3f261f7a245";
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
