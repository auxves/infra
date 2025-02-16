{ ... }: {
  sops.secrets."forgejo/runner-env" = { };

  apps.forgejo = {
    presets.forgejo-runner.enable = true;
  };
}
