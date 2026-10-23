{ ... }: {
  boot.extraModprobeConfig = ''
    # Copy Fail (CVE-2026-31431)
    install algif_aead /run/current-system/sw/bin/false

    # Dirty Frag
    install esp4 /run/current-system/sw/bin/false
    install esp6 /run/current-system/sw/bin/false
    install rxrpc /run/current-system/sw/bin/false
  '';

  security.pki.caCertificateBlacklist = [
    # eMudhra certificates
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];
}
