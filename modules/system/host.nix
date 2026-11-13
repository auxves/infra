{ host, ... }: {
  networking.hostName = host.name;

  nixpkgs.hostPlatform = host.system;
}
