{ ... }: {
  disko.devices.zpool.storage.datasets."services/minecraft-vz".type = "zfs_fs";

  virtualisation.oci-containers.containers.minecraft-vz = {
    image = "itzg/minecraft-server:java21-graalvm";
    autoStart = true;

    environment = {
      EULA = "true";
      MEMORY = "8G";
      SEED = "gi//2WUWTxu6XfdK";
      SERVER_PORT = "25560";
      TYPE = "FABRIC";
      USE_AIKAR_FLAGS = "true";
      USE_SIMD_FLAGS = "true";
      VERSION = "1.20.4";
    };

    volumes = [ "/storage/services/minecraft-vz:/data" ];

    extraOptions = [ "--network=lan:ip=2600:1700:78c0:130f:abcd::2e4c" ];
  };
}
