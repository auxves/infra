{ inputs, ... }: {
  flake.modules = {
    nixos.default = {
      imports = with inputs.self.modules.nixos; [
        nix
        builders
        meta
        monitoring
        system
        emulation
        gitops
        shell
        home
        development
        graphical
        tailscale
        traefik
        alloy
        exporters
        services
        containers
        volumes
        prepull
        podman
        db
        forgejo-runner
        oci-containers
        ssh
        kernel
      ] ++ [
        inputs.sops.nixosModules.sops
      ];
    };

    darwin.default = {
      imports = with inputs.self.modules.darwin; [
        nix
        builders
        meta
        monitoring
        system
        shell
        home
        development
        graphical
      ] ++ [
        inputs.sops.darwinModules.sops
      ];
    };
  };
}
