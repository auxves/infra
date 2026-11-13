{ config, lib, pkgs, ... }:
let
  cfg = config.services.yabai;

  options = {
    mouse_follows_focus = "off";
    focus_follows_mouse = "off";
    window_origin_display = "default";
    window_placement = "second_child";
    window_shadow = "on";
    window_animation_duration = 0.0;
    window_opacity_duration = 0.0;
    active_window_opacity = 1.0;
    normal_window_opacity = 0.90;
    window_opacity = "off";
    split_ratio = 0.50;
    split_type = "auto";
    auto_balance = "off";
    top_padding = 12;
    bottom_padding = 12;
    left_padding = 12;
    right_padding = 12;
    window_gap = 12;
    layout = "bsp";
    mouse_modifier = "fn";
    mouse_action1 = "move";
    mouse_action2 = "resize";
    mouse_drop_action = "swap";
  };

  YABAI = "${cfg.package}/bin/yabai";

  extra = ''
    ${YABAI} -m rule --add app="^System Settings$" manage=off
    ${YABAI} -m rule --add app="^Archive Utility$" manage=off
    ${YABAI} -m rule --add app="^Finder$" title="(Copy|Connect|Move|Info|Pref)" manage=off
    ${YABAI} -m rule --add app="^App Store$" manage=off
    ${YABAI} -m rule --add app="^Shottr$" manage=off
    ${YABAI} -m rule --add app="^Parallels Desktop$" title="Control Center" manage=off
  '';

  configFile = pkgs.writeScript "yabairc" ''
    ${builtins.concatStringsSep "\n"
      (lib.mapAttrsToList (k: v: "${YABAI} -m config ${k} ${toString v}") options)}

    ${extra}
  '';
in
{
  options.services.yabai = with lib; {
    enable = mkEnableOption "Enable Yabai tiling window manager";

    package = mkOption {
      type = types.package;
      default = pkgs.yabai;
      description = "This option specifies the yabai package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    launchd.agents.yabai = {
      enable = true;
      config = {
        Label = "com.koekeishiya.yabai";
        ProgramArguments = [ YABAI "-c" "${configFile}" ];

        KeepAlive = {
          SuccessfulExit = false;
          Crashed = true;
        };

        RunAtLoad = true;
        ProcessType = "Interactive";
        StandardOutPath = "/tmp/yabai_out.log";
        StandardErrorPath = "/tmp/yabai_err.log";
        Nice = -20;
      };
    };

    home.packages = [ pkgs.yabai ];
  };
}
