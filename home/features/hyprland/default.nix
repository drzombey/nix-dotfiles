{ ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    # Paket kommt vom NixOS-Modul (programs.hyprland in systems/braavos)
    package = null;
    portalPackage = null;

    # hyprland.conf statt hyprland.lua: der Lua-Generator von Home-Manager
    # erzeugt derzeit ungültiges Lua (hl.$mod(...), hl.exec-once(...)) und
    # trifft die echte Lua-API von Hyprland (hl.config{...}) noch nicht.
    configType = "hyprlang";

    settings = {
      monitor = ",preferred,auto,1";

      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$menu" = "wofi --show drun";

      exec-once = [
        "waybar"
        "mako"
        "nm-applet --indicator"
        "systemctl --user start hyprpolkitagent"
      ];

      input = {
        kb_layout = "de";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        layout = "dwindle";
      };

      decoration.rounding = 8;
      animations.enabled = true;

      # Software-Cursor (Hardware-Cursor der Intel-GPU kaputt)
      cursor.no_hardware_cursors = true;

      bind = [
        # Programme
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $menu"
        "$mod, E, exec, nautilus"
        "$mod, B, exec, google-chrome-stable"

        # Fenster
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod SHIFT, E, exit"

        # Fokus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"

        # Screenshot (Bereich -> Zwischenablage)
        "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Sperren
        "$mod, L, exec, hyprlock"
      ];

      # Fenster mit Maus verschieben/skalieren
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Multimedia-Tasten
      bindel = [
        ",XF86AudioRaiseVolume, exec, pamixer -i 5"
        ",XF86AudioLowerVolume, exec, pamixer -d 5"
        ",XF86MonBrightnessUp, exec, brightnessctl s +5%"
        ",XF86MonBrightnessDown, exec, brightnessctl s 5%-"
      ];
      bindl = [
        ",XF86AudioMute, exec, pamixer -t"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;
      background = [
        {
          monitor = "";
          color = "rgb(20, 22, 30)";
        }
      ];
      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 2;
          placeholder_text = "Passwort…";
          fade_on_empty = true;
        }
      ];
      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 56;
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        # Nach 10 Min sperren
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        # Nach 15 Min Bildschirm aus
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
