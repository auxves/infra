final: prev: {
  buildNuModule = final.callPackage ./buildNuModule { };
  writeNushellApplication = final.callPackage ./writeNushellApplication { };
}
