{ config, lib, pkgs, ... }:
let
  settings = {
    user.name = "auxves";
    user.email = "me@auxves.dev";

    init.defaultBranch = "main";

    pull.rebase = true;
    rebase.autoStash = true;

    gpg.format = "ssh";

    merge.autoStash = true;

    credential.helper = [ "cache --timeout=86400" ];
  };

  ignores = [
    ".DS_Store"
    "Desktop.ini"
    ".Spotlight-V100"
    ".Trashes"
    "._*"
    "Thumbs.db"
    ".direnv"
    ".venv"
  ];
in
{
  config = lib.mkIf config.programs.git.enable {
    programs.git = {
      package = pkgs.gitMinimal;
      inherit settings ignores;

      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE";
        signByDefault = true;
      };

      lfs.enable = true;
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        side-by-side = true;
        hunk-header-style = "omit";
        syntax-theme = "Nord";
        tabs = 2;
      };
    };

    programs.git-credential-oauth.enable = true;
  };
}
