{ config, lib, ... }:
let
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

  extra = ''
    yabai -m rule --add app="^System Settings$" manage=off
    yabai -m rule --add app="^Archive Utility$" manage=off
    yabai -m rule --add app="^Finder$" title="(Copy|Connect|Move|Info|Pref)" manage=off
    yabai -m rule --add app="^App Store$" manage=off
    yabai -m rule --add app="^Shottr$" manage=off
    yabai -m rule --add app="^Parallels Desktop$" title="Control Center" manage=off
  '';
in
{
  config = lib.mkIf config.services.yabai.enable {
    services.yabai = {
      config = options;
      extraConfig = extra;
    };
  };
}
