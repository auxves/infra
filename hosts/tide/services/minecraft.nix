{ ... }: {
  disko.devices.zpool.storage.datasets."services/minecraft-vz".type = "zfs_fs";

  virtualisation.oci-containers.containers.minecraft-vz = {
    image = "itzg/minecraft-server:java21-graalvm@sha256:3463d4b031a9afa1c9e44d5e6ea0b197a79f126e837e016c59633baff2e507c9";
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
