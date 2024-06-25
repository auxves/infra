{ lib, pkgs, ... }: {
  # imports = lib.readModules ./.;

  systemd.targets."podman-networks" = {
    unitConfig.Description = "Podman networks needed by services.";
    wantedBy = [ "network-online.target" ];
  };

  systemd.services."podman-network-lan" = {
    path = [ pkgs.podman ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.podman}/bin/podman network rm -f lan";
    };

    script = ''
      podman network exists lan || podman network create lan -d macvlan -o parent=enp130s0 --subnet 192.168.4.0/22 --subnet 2600:1700:78c0:130f::/64 --ipv6
    '';

    partOf = [ "podman-networks.target" ];
    wantedBy = [ "podman-networks.target" ];
  };
}
