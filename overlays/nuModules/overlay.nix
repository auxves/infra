final: prev: {
  nuModules = prev.lib.makeScope prev.newScope (self: {
    ao3 = self.callPackage ./ao3 { };
  });
}
