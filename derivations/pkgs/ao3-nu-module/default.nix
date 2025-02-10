{ buildNuModule }:
buildNuModule {
  name = "ao3";
  src = builtins.path { path = ./.; };
}
