{ self, lib, config, host, ... }:
let
  cfg = config.modules.home;
in
{
  imports = [ self.inputs.home-manager."${host.variant}Modules".home-manager ];

  options.modules.home = with lib; {
    enable = mkEnableOption "Enable home-manager";

    user = mkOption {
      type = types.str;
      default = "arno";
    };

    modules = mkOption {
      type = types.listOf types.anything;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = { inherit self host; };

    home-manager.users.${cfg.user}.imports = [ ../home ] ++ cfg.modules;

    users.users.${cfg.user} = {
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE" ];
    } // lib.optionalAttrs (host.platform == "linux") {
      home = "/home/${cfg.user}";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    } // lib.optionalAttrs (host.platform == "darwin") {
      home = "/Users/${cfg.user}";
    };
  };
}
