{ config, lib, ... }:
let
  cfg = config.services.skhd;

  focusKey = "fn - space";

  YABAI = "${config.services.yabai.package}/bin/yabai";
  SKHD = "${cfg.package}/bin/skhd";

  keybindings = {
    # Terminal
    "fn - x" = ''
      osascript -e 'tell application "System Events" to tell process "Warp"' -e 'click menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1' -e 'end tell' -e 'tell application "Warp" to activate'
      sleep 0.1 && ${SKHD} -k "${focusKey}"
    '';

    # Browser
    "fn - s" = ''
      osascript -e 'tell app "Safari"' -e 'make new document' -e 'activate' -e 'end tell'
      sleep 0.1 && ${SKHD} -k "${focusKey}"
    '';

    # Finder
    "fn - d" = ''
      osascript -e 'tell application "Finder"' -e 'activate' -e 'make new Finder window to home' -e 'end tell'
      sleep 0.1 && ${SKHD} -k "${focusKey}"
    '';

    # Code
    "fn - c" = ''
      code -n
      sleep 0.1 && ${SKHD} -k "${focusKey}"
    '';

    ${focusKey} = "${YABAI} -m window --display mouse --space mouse --focus";

    "shift + cmd - left" = "${YABAI} -m window --display prev --focus";
    "shift + cmd - right" = "${YABAI} -m window --display next --focus";

    # equalize size of windows
    "shift + alt - 0" = "${YABAI} -m space --balance";

    # move window
    "shift + cmd - h" = "${YABAI} -m window --warp west --focus";
    "shift + cmd - j" = "${YABAI} -m window --warp south --focus";
    "shift + cmd - k" = "${YABAI} -m window --warp north --focus";
    "shift + cmd - l" = "${YABAI} -m window --warp east --focus";

    # mirror tree y-axis
    "shift + alt - x" = "${YABAI} -m space --mirror y-axis";

    # toggle window native fullscreen
    "shift + alt - f" = "${YABAI} -m window --toggle native-fullscreen";

    # toggle window split type
    "alt - e" = "${YABAI} -m window --toggle split";

    # float / unfloat window
    "alt - t" = "${YABAI} -m window --toggle float";

    # yeet window to last workspace
    "alt - y" = "${YABAI} -m window --space last";
  };

  mkBinding = key: command: "${key} : ${builtins.replaceStrings ["\n"] ["; "] command}";

  configText = builtins.concatStringsSep "\n\n" (lib.mapAttrsToList mkBinding keybindings);
in
{
  config = lib.mkIf cfg.enable {
    services.skhd.config = configText;
  };
}
