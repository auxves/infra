{ ... }: {
  boot.extraModprobeConfig = ''
    # Copy Fail (CVE-2026-31431)
    install algif_aead /run/current-system/sw/bin/false

    # Dirty Frag
    install esp4 /run/current-system/sw/bin/false
    install esp6 /run/current-system/sw/bin/false
    install rxrpc /run/current-system/sw/bin/false
  '';
}
