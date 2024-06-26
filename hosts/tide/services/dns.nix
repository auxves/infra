{ ... }: {
  disko.devices.zpool.storage.datasets."services/dns".type = "zfs_fs";

  virtualisation.oci-containers.containers.dnsmasq = {
    image = "jpillora/dnsmasq@sha256:98b69ad825942089fb7c4b9153e3c5af0205eda3a103c691e30b1a13fd912830";
    autoStart = true;

    volumes = [
      "/storage/services/dns/dnsmasq.conf:/etc/dnsmasq.conf"
    ];

    extraOptions = [
      "--network=lan:ip6=2600:1700:78c0:130f:abcd::4a0c,mac=62:c1:5b:7f:15:38"
    ];
  };
}
