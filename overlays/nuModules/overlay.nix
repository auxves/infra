final: prev: {
  nuModules = prev.lib.makeScope prev.newScope (scope: {
    ao3 = scope.callPackage ./ao3 { };
  });
}
