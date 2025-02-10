{ writeNushellApplication, curl, pup, ao3-nu-module }:
writeNushellApplication {
  name = "sync-ao3";

  runtimeInputs = [ curl pup ao3-nu-module ];

  text = builtins.readFile ./main.nu;
}
