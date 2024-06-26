{ ... }: {
  disko.devices.zpool.storage.datasets."services/dns".type = "zfs_fs";

  virtualisation.oci-containers.containers.dnsmasq = {
    image = "jpillora/dnsmasq@sha256:98b69ad825942089fb7c4b9153e3c5af0205eda3a103c691e30b1a13fd912830";
    autoStart = true;

    ports = [ "[fd7a:115c:a1e0::4d01:292e]:53:53" ];

    volumes = [
      "/storage/services/dns/dnsmasq.conf:/etc/dnsmasq.conf"
    ];
  };
}
