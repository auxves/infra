{ self, config, pkgs, ... }: {
  sops.secrets."forgejo/runner-env" = { };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;

    instances.main = {
      enable = true;
      name = config.networking.hostName;
      url = "https://${self.hosts.tide.cfg.apps.forgejo.ingress.domain}";
      tokenFile = config.sops.secrets."forgejo/runner-env".path;

      labels = [
        "ubuntu-latest:docker://ubuntu:noble"
        "nixos-latest:docker://nixos/nix"
      ];

      settings = {
        container.enable_ipv6 = true;
      };
    };
  };
}
