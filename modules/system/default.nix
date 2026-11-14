{ inputs, ... }: {
  flake.modules = {
    nixos.default = {
      imports = with inputs.self.modules.nixos; [
        nix
        builders
        meta
        monitoring
        system
        shell
        tailscale
        services
        containers
        volumes
        prepull
        podman
        db
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
      ] ++ [
        inputs.sops.darwinModules.sops
      ];
    };
  };
}
