{
  name = "auxves";
  email = "me@auxves.dev";

  config = {
    init.defaultBranch = "main";

    pull.rebase = true;
    rebase.autoStash = true;

    commit.gpgsign = true;
    gpg.format = "ssh";
    user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHiwuwSpFayBr5vka7mNjmFkPlKXK7bUkRYxJspY5WE";

    pager = {
      diff = "delta";
      show = "delta";
      log = "delta";
      blame = "delta";
      grep = "delta";
      reflog = "delta";
    };

    interactive.diffFilter = "delta --color-only";

    delta = {
      side-by-side = true;
      hunk-header-style = "omit";
      syntax-theme = "Nord";
      tabs = 2;
    };

    core.editor = "code --wait";

    diff.tool = "code";
    "difftool \"code\"".cmd = ''code --wait --diff "$LOCAL" "$REMOTE"'';

    merge.autoStash = true;
    merge.tool = "code";
    "mergetool \"code\"".cmd = ''code --wait "$MERGED"'';
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
}
