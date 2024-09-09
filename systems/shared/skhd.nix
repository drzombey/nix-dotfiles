{ pkgs
, lib
, inputs
, config
, ...
}: {
  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = ''
      :: default : yabai -m config active_window_opacity 1; yabai -m config normal_window_opacity 1;

      lalt - e : yabai -m space --layout bsp
      lalt - s : yabai -m space --layout stack

      lalt - left  : yabai -m window --focus west
      lalt - down  : yabai -m window --focus south
      lalt - up    : yabai -m window --focus north
      lalt - right : yabai -m window --focus east


      lalt + shift - left : yabai -m window --warp west
      lalt + shift - right : yabai -m window --warp east
      lalt + shift - up : yabai -m window --warp north
      lalt + shift - down : yabai -m window --warp south

      lalt + shift - h : yabai -m window --toggle bsp
      lalt + shift - v : yabai -m window --toggle split
      lalt - h : yabai -m config split_type horizontal
      lalt - v : yabai -m config split_type vertical

      lalt - 1 : yabai -m space --focus 1 && skhd -k "alt + cmd + ctrl + shift - 1"
      lalt - 2 : yabai -m space --focus 2 && skhd -k "alt + cmd + ctrl + shift - 2"
      lalt - 3 : yabai -m space --focus 3 && skhd -k "alt + cmd + ctrl + shift - 3"
      lalt - 4 : yabai -m space --focus 4 && skhd -k "alt + cmd + ctrl + shift - 4"
      lalt - 5 : yabai -m space --focus 5 && skhd -k "alt + cmd + ctrl + shift - 5"
      lalt - 6 : yabai -m space --focus 6 && skhd -k "alt + cmd + ctrl + shift - 6"

      lalt + shift - 1 : yabai -m window --space 1 && yabai -m space --focus 1 && skhd -k "alt + cmd + ctrl + shift - 1"
      lalt + shift - 2 : yabai -m window --space 2 && yabai -m space --focus 2 && skhd -k "alt + cmd + ctrl + shift - 2"
      lalt + shift - 3 : yabai -m window --space 3 && yabai -m space --focus 3 && skhd -k "alt + cmd + ctrl + shift - 3"
      lalt + shift - 4 : yabai -m window --space 4 && yabai -m space --focus 4 && skhd -k "alt + cmd + ctrl + shift - 4"
      lalt + shift - 5 : yabai -m window --space 5 && yabai -m space --focus 5 && skhd -k "alt + cmd + ctrl + shift - 5"
      lalt + shift - 6 : yabai -m window --space 6 && yabai -m space --focus 6 && skhd -k "alt + cmd + ctrl + shift - 6"

      lalt - f : yabai -m window --toggle float
      lalt + shift - q : yabai -m window --close

      lalt - return : alacritty msg create-window || open -na alacritty
      lalt - b : open -na /Applications/Google\ Chrome.app/

      lalt - l : pmset displaysleepnow


      # defines a new mode 'resize' with an on_enter command, that captures keypresses
      :: resize @ : yabai -m config active_window_border_color 0xFFFF00FF

      # from 'default' mode, activate mode 'resize'
      # (this is the key combination you want to use to enter resize mode)
      resize < lalt - r ; default
      default < lalt - r ; resize

      # from 'resize' mode, activate mode 'default'
      # (this is the keypress required to leave resize mode)
      resize < escape ; default

      # resize commands
      resize < left : yabai -m window --resize left:-50:0; \
                        yabai -m window --resize right:-50:0
      resize < down : yabai -m window --resize bottom:0:50; \
                        yabai -m window --resize top:0:50
      resize < up   : yabai -m window --resize top:0:-50; \
                        yabai -m window --resize bottom:0:-50
      resize < right : yabai -m window --resize right:50:0; \
                        yabai -m window --resize left:50:0
    '';
  };
}
