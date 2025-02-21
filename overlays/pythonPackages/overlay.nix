final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      octodns-cloudflare = python-final.callPackage ./octodns-cloudflare { };
    })
  ];
}
