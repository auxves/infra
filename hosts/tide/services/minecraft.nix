{ ... }: {
  disko.devices.zpool.storage.datasets."services/minecraft-vz".type = "zfs_fs";

  virtualisation.oci-containers.containers.minecraft-vz = {
    image = "itzg/minecraft-server:java21-graalvm@sha256:9f90b027ddd85530108a9402d7762c157553b2ee5c3b70ab0a62d8d7e1fbca30";
    autoStart = true;

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
