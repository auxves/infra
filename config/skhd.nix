let
  focusKey = "fn - space";

  keybindings = {
    # Terminal
    "fn - x" = ''
      osascript -e 'tell application "System Events" to tell process "Warp"' -e 'click menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1' -e 'end tell' -e 'tell application "Warp" to activate'
      sleep 0.1 && skhd -k "${focusKey}"
    '';

    # Browser
    "fn - s" = ''
      osascript -e 'tell app "Safari"' -e 'make new document' -e 'activate' -e 'end tell'
      sleep 0.1 && skhd -k "${focusKey}"
    '';

    # Finder
    "fn - d" = ''
      osascript -e 'tell application "Finder"' -e 'activate' -e 'make new Finder window to home' -e 'end tell'
      sleep 0.1 && skhd -k "${focusKey}"
    '';

    # Code
    "fn - c" = ''
      code -n
      sleep 0.1 && skhd -k "${focusKey}"
    '';

    ${focusKey} = "yabai -m window --display mouse --space mouse --focus";

    "shift + cmd - left" = "yabai -m window --display prev --focus";
    "shift + cmd - right" = "yabai -m window --display next --focus";

    # equalize size of windows
    "shift + alt - 0" = "yabai -m space --balance";

    # move window
    "shift + cmd - h" = "yabai -m window --warp west --focus";
    "shift + cmd - j" = "yabai -m window --warp south --focus";
    "shift + cmd - k" = "yabai -m window --warp north --focus";
    "shift + cmd - l" = "yabai -m window --warp east --focus";

    # mirror tree y-axis
    "shift + alt - x" = "yabai -m space --mirror y-axis";

    # toggle window native fullscreen
    "shift + alt - f" = "yabai -m window --toggle native-fullscreen";

    # toggle window split type
    "alt - e" = "yabai -m window --toggle split";

    # float / unfloat window
    "alt - t" = "yabai -m window --toggle float";

    # yeet window to last workspace
    "alt - y" = "yabai -m window --space last";
  };

  mkBinding = key: command: "${key} : ${builtins.replaceStrings ["\n"] ["; "] command}";

  mapAttrsToList = f: attrs: map (name: f name attrs.${name}) (builtins.attrNames attrs);
in
builtins.concatStringsSep "\n\n" (mapAttrsToList mkBinding keybindings)
