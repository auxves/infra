{ buildNuModule, pup }:
buildNuModule {
  name = "ao3";
  src = builtins.path { path = ./.; };

  buildInputs = [ pup ];
}
