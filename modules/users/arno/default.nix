{ inputs, ... }: {
  flake.modules.nixos.users-arno = { lib, config, ... }: {
    imports = [
      inputs.self.modules.nixos.home
    ];

    config = {
      users.users.arno = {
        home = "/home/arno";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE" ];
      };

      home-manager.users.arno.imports = [
        inputs.self.modules.homeManager.users-arno
      ];
    };
  };

  flake.modules.darwin.users-arno = { lib, config, ... }: {
    imports = [
      inputs.self.modules.darwin.home
    ];

    config = {
      users.users.arno = {
        home = "/Users/arno";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE" ];
      };

      home-manager.users.arno.imports = [
        inputs.self.modules.homeManager.users-arno
      ];

      system.primaryUser = "arno";

      launchd.user.envVariables = {
        PATH = inputs.self.lib.internal.replaceAll
          {
            "$HOME" = config.home-manager.users.arno.home.homeDirectory;
            "$USER" = "arno";
          }
          config.environment.systemPath;
      }
      // config.home-manager.users.arno.home.sessionVariables;
    };
  };
}
