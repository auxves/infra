{ writeNushellApplication, curl, pup, ao3 }:
writeNushellApplication {
  name = "sync-ao3";

  runtimeInputs = [ curl pup ao3 ];

  text = builtins.readFile ./main.nu;
}
