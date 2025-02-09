{ writeNushellApplication, curl, pup }:
writeNushellApplication {
  name = "sync-ao3";

  runtimeInputs = [ curl pup ];

  modules = [
    { name = "ao3"; path = ./ao3; }
  ];

  text = builtins.readFile ./main.nu;
}
