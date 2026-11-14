{ inputs, ... }: {
  flake.modules.darwin.blaze = {
    imports = [ inputs.self.modules.darwin.default ];

    networking.hostName = "blaze";

    presets = {
      home.enable = true;
      development.enable = true;
      graphical.enable = true;
      builders.outsource = true;
    };
  };
}
