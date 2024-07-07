{ ... }: {
  virtualisation.oci-containers.containers.loki = {
    image = "grafana/loki:3.1.0@sha256:d947e68a84d9e44915dfa08c3bec27e2124efd5ba6c83443eb53578101ec69e3";
  };

  virtualisation.oci-containers.containers.promtail = {
    image = "grafana/promtail:3.1.0@sha256:b3db8e7b1cba0e8c45ce2ae72ebddfd88ebdcae86383f1680edf0074e9010ff6";
    user = "root:root";

    volumes = [
      "/var/log:/var/log:ro"
      "/etc/machine-id:/etc/machine-id:ro"
      "${./promtail.yaml}:/etc/promtail/config.yml:ro"
    ];
  };
}
