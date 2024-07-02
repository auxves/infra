{ ... }: {
  imports = [
    ./traefik
    ./home-assistant
    ./dns.nix
    ./minecraft.nix
  ];
}
