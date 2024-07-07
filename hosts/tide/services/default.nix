{ ... }: {
  imports = [
    ./traefik
    ./home-assistant
    ./minecraft
    ./prometheus
    ./grafana
    ./loki
  ];
}
