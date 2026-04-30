{ ... }: {
  # CVE-2026-31431

  boot.blacklistedKernelModules = [
    "algif_aead"
  ];

  boot.extraModprobeConfig = ''
    install algif_aead /run/current-system/sw/bin/false
  '';
}
