{ pkgs, inputs, nvim-config, lib, username, ... }:

let


  system = pkgs.stdenv.hostPlatform.system;
  homeDirectory = "/home/${username}";
  caelestiaCli = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default;


  caelestiaCliPatched = caelestiaCli.overrideAttrs (old: {
    patchPhase = (old.patchPhase or "") + ''
      sed -i '1ifrom __future__ import annotations' src/caelestia/utils/material/generator.py
    '';
  });

  #celestia patch
  caelestiaShellPatched = inputs.caelestia-shell.packages.${system}.caelestia-shell.override {
    withCli = true;
    caelestia-cli = caelestiaCliPatched;
  };

  #disbale idle
  caelestiaShellConfig = pkgs.writeText "caelestia-shell.json" (builtins.toJSON {
    bar.status.showBattery = false;
    general.idle.timeouts = [
      {
        timeout = 180;
        idleAction = "lock";
      }
    ];
    paths.wallpaperDir = "~/Pictures";
  });


  #theme for kitty
  caelestiaKittyThemeGenerator = pkgs.writeText "caelestia-kitty-theme.py" ''
    import json
    import re
    import sys
    from pathlib import Path

    scheme_path = Path(sys.argv[1])
    template_path = Path(sys.argv[2])
    theme_path = Path(sys.argv[3])

    colours = json.loads(scheme_path.read_text()).get("colours", {})
    template = template_path.read_text()

    def replace(match):
      parts = match.group(1).strip().split(".")
      if len(parts) != 2:
        return match.group(0)

      name, form = parts
      value = colours.get(name)
      if value is None or form != "hex":
        return match.group(0)

      return value

    theme_path.parent.mkdir(parents=True, exist_ok=True)
    theme_path.write_text(re.sub(r"\{\{((?:(?!\{\{|\}\}).)*)\}\}", replace, template))
  '';

 #config for kitty terminal
  caelestiaKittyTheme = ''
    foreground #{{ onSurface.hex }}
    background #{{ surface.hex }}
    selection_foreground #{{ onSecondary.hex }}
    selection_background #{{ secondary.hex }}
    cursor #{{ secondary.hex }}
    cursor_text_color #{{ onSecondary.hex }}
    url_color #{{ primary.hex }}

    color0 #{{ term0.hex }}
    color1 #{{ term1.hex }}
    color2 #{{ term2.hex }}
    color3 #{{ term3.hex }}
    color4 #{{ term4.hex }}
    color5 #{{ term5.hex }}
    color6 #{{ term6.hex }}
    color7 #{{ term7.hex }}
    color8 #{{ term8.hex }}
    color9 #{{ term9.hex }}
    color10 #{{ term10.hex }}
    color11 #{{ term11.hex }}
    color12 #{{ term12.hex }}
    color13 #{{ term13.hex }}
    color14 #{{ term14.hex }}
    color15 #{{ term15.hex }}

    active_tab_foreground #{{ onPrimary.hex }}
    active_tab_background #{{ primary.hex }}
    inactive_tab_foreground #{{ onSurfaceVariant.hex }}
    inactive_tab_background #{{ surfaceContainerHigh.hex }}
    tab_bar_background #{{ surface.hex }}
  '';
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;

  # Use your current NixOS release version.
  # Do not randomly bump this later.
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    kitty
    eww
    rofi
    wl-clipboard
    cliphist
    grim
    slurp
    awww





    # needed by npm-based nvim tooling / Mason
    nodejs_22
    gcc
    gnumake
    unzip
    wget
    curl
    git

    # useful for nvim plugins
    ripgrep
    fd
    tree-sitter

    # your config also references these
    clang-tools
    rust-analyzer
    jdt-language-server
    pyright
    arduino-cli

    nautilus

    #zen browser
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default




  ];


  #Variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";


  };

  #zsh Variables
  programs.zsh.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
  };

  services.udiskie = {
      enable = true;
      settings = {
          # workaround for
          # https://github.com/nix-community/home-manager/issues/632
          program_options = {
              # replace with your favorite file manager
              file_manager = "${pkgs.nautilus}";
          };
      };
  };


  fonts.fontconfig.enable = true;

  #kitty setting (pair with caelesitia)
  programs.kitty = {
    enable = true;

    font = {
      package = pkgs.nerd-fonts.caskaydia-cove;
      name = "CaskaydiaCove Nerd Font Mono";
      size = 9.0;
    };

    extraConfig = ''
      include ${homeDirectory}/.local/state/caelestia/theme/kitty.conf
    '';

    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      enable_audio_bell = false;
      window_padding_width = 25;
      cursor_trail = 1;
      background_opacity = "0.60";
      hide_window_decorations = true;
      confirm_os_window_close = 0;

      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
    };
  };

  #Caelestia pre-configured rice
  programs.caelestia = {
    enable = true;
    package = caelestiaShellPatched;

    cli.enable = true;
    cli.package = caelestiaCliPatched;

    systemd = {
      enable = false; # start it from Hyprland instead if you want
      target = "graphical-session.target";
      environment = [];
    };

  };

  #wriatble config fix
  home.activation.caelestiaWritableConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    config_dir="$HOME/.config/caelestia"
    config_file="$config_dir/shell.json"

    $DRY_RUN_CMD mkdir -p "$config_dir"

    if [ -L "$config_file" ]; then
      $DRY_RUN_CMD rm "$config_file"
    fi

    if [ ! -e "$config_file" ]; then
      $DRY_RUN_CMD install -m 0644 ${caelestiaShellConfig} "$config_file"
    fi

    $DRY_RUN_CMD chmod u+w "$config_file"
  '';

  #theme config fix.
  home.activation.caelestiaKittyTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    scheme_file="$HOME/.local/state/caelestia/scheme.json"
    template_file="$HOME/.config/caelestia/templates/kitty.conf"
    theme_file="$HOME/.local/state/caelestia/theme/kitty.conf"

    $DRY_RUN_CMD mkdir -p "$(dirname "$theme_file")"

    if [ -f "$scheme_file" ] && [ -f "$template_file" ]; then
      $DRY_RUN_CMD ${pkgs.python3}/bin/python ${caelestiaKittyThemeGenerator} "$scheme_file" "$template_file" "$theme_file"
    elif [ ! -e "$theme_file" ]; then
      $DRY_RUN_CMD touch "$theme_file"
    fi
  '';




  #Hyprland config
  wayland.windowManager.hyprland = {
    enable = true;



    settings = {
      "$mod" = "SUPER";

      cursor = {
        no_hardware_cursors = true;
      };

      monitor = [
        "HDMI-A-1, 2560x1440@120, 0x0, 1"
        ",preferred@120,auto,1"
      ];

      exec-once = [
        "caelestia shell" # prebuilt rice.
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;
        };
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };
    };

    extraConfig = ''
      $terminal = kitty
      $editor = kitty nvim
      $browser = zen-browser

      # Caelestia shell global shortcuts.
      exec = hyprctl dispatch submap global
      submap = global

      # Launcher / shell panels
      bindi = $mod, Super_L, global, caelestia:launcher
      bindin = $mod, catchall, global, caelestia:launcherInterrupt
      bindin = $mod, mouse:272, global, caelestia:launcherInterrupt
      bindin = $mod, mouse:273, global, caelestia:launcherInterrupt
      bindin = $mod, mouse_up, global, caelestia:launcherInterrupt
      bindin = $mod, mouse_down, global, caelestia:launcherInterrupt
      bind = $mod, Space, global, caelestia:launcher
      bind = $mod, N, global, caelestia:sidebar
      bind = $mod, K, global, caelestia:showall
      bind = $mod, slash, global, caelestia:showall
      bind = $mod, L, global, caelestia:lock
      bind = $mod, Backspace, global, caelestia:session
      bind = CTRL ALT, Delete, global, caelestia:session
      bindl = CTRL ALT, C, global, caelestia:clearNotifs

      # Window management
      bind = $mod, Q, killactive
      bind = ALT, F4, killactive
      bind = $mod, Delete, exit
      bind = $mod, W, exec, hyprctl --batch "dispatch togglefloating; dispatch resizeactive exact 95% 95%; dispatch centerwindow"
      bind = $mod, G, togglegroup
      bind = ALT, Return, fullscreen
      bind = $mod SHIFT, F, pin
      bind = $mod, J, togglesplit
      bind = $mod CTRL, H, changegroupactive, b
      bind = $mod CTRL, L, changegroupactive, f

      # Focus
      bind = $mod, left, movefocus, l
      bind = $mod, right, movefocus, r
      bind = $mod, up, movefocus, u
      bind = $mod, down, movefocus, d
      bind = ALT, Tab, cyclenext

      # Resize active window
      binde = $mod SHIFT, right, resizeactive, 30 0
      binde = $mod SHIFT, left, resizeactive, -30 0
      binde = $mod SHIFT, up, resizeactive, 0 -30
      binde = $mod SHIFT, down, resizeactive, 0 30

      # Move active tiled window around the workspace.
      binde = $mod SHIFT CTRL, left, movewindow, l
      binde = $mod SHIFT CTRL, right, movewindow, r
      binde = $mod SHIFT CTRL, up, movewindow, u
      binde = $mod SHIFT CTRL, down, movewindow, d
      # Old floating-aware version needs jq, which is not in this config:
      # $moveactivewindow = grep -q "true" <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive
      # binde = $mod SHIFT CTRL, left, exec, $moveactivewindow -30 0 || hyprctl dispatch movewindow l
      # binde = $mod SHIFT CTRL, right, exec, $moveactivewindow 30 0 || hyprctl dispatch movewindow r
      # binde = $mod SHIFT CTRL, up, exec, $moveactivewindow 0 -30 || hyprctl dispatch movewindow u
      # binde = $mod SHIFT CTRL, down, exec, $moveactivewindow 0 30 || hyprctl dispatch movewindow d

      # Move / resize with mouse
      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow
      # Old keyboard-held move/resize binds, left for manual review:
      # bindm = $mod, Z, movewindow
      # bindm = $mod, X, resizewindow

      # Apps
      bind = $mod, T, exec, $terminal
      bind = $mod, C, exec, $editor
      bind = $mod, F, exec, $browser
      bind = CTRL SHIFT, Escape, exec, kitty btop
      # Dolphin is not installed in this config:
      # bind = $mod, E, exec, dolphin

      # Rofi entries that work with the installed rofi package.
      bind = $mod, Tab, exec, pkill -x rofi || rofi -show window
      # Caelestia owns the launcher now; rofi drun is kept here for review:
      # bind = $mod, Space, exec, pkill -x rofi || rofi -show drun
      bind = $mod, V, exec, pkill -x rofi || cliphist list | rofi -dmenu -p clipboard | cliphist decode | wl-copy
      bind = $mod SHIFT, V, exec, cliphist wipe
      # Old rofi helper scripts are not present:
      # bind = $mod SHIFT, E, exec, pkill -x rofi || rofi -show filebrowser
      # bind = $mod, comma, exec, pkill -x rofi || emoji-picker
      # bind = $mod, period, exec, pkill -x rofi || glyph-picker

      # Hardware controls handled by Caelestia.
      bindl = , XF86MonBrightnessUp, global, caelestia:brightnessUp
      bindl = , XF86MonBrightnessDown, global, caelestia:brightnessDown
      bindl = CTRL SUPER, Space, global, caelestia:mediaToggle
      bindl = , XF86AudioPlay, global, caelestia:mediaToggle
      bindl = , XF86AudioPause, global, caelestia:mediaToggle
      bindl = CTRL SUPER, Equal, global, caelestia:mediaNext
      bindl = , XF86AudioNext, global, caelestia:mediaNext
      bindl = CTRL SUPER, Minus, global, caelestia:mediaPrev
      bindl = , XF86AudioPrev, global, caelestia:mediaPrev
      bindl = , XF86AudioStop, global, caelestia:mediaStop
      # Old volume scripts are not present:
      # bindl = , F10, exec, volumecontrol -o m
      # binde = , F11, exec, volumecontrol -o d
      # binde = , F12, exec, volumecontrol -o i
      # bindl = , XF86AudioMute, exec, volumecontrol -o m
      # bindl = , XF86AudioMicMute, exec, volumecontrol -i m
      # binde = , XF86AudioLowerVolume, exec, volumecontrol -o d
      # binde = , XF86AudioRaiseVolume, exec, volumecontrol -o i

      # Screenshots
      bindl = , Print, exec, caelestia screenshot
      bind = $mod SHIFT, S, global, caelestia:screenshotFreeze
      bind = $mod SHIFT ALT, S, global, caelestia:screenshot
      # hyprpicker and old screenshot scripts are not present:
      # bind = $mod SHIFT, P, exec, hyprpicker -an
      # bind = $mod CTRL, P, exec, screenshot sf
      # bindl = $mod ALT, P, exec, screenshot m

      # Restart shell
      bindr = CTRL SUPER SHIFT, R, exec, qs -c caelestia kill
      bindr = CTRL SUPER ALT, R, exec, qs -c caelestia kill; sleep .1; caelestia shell -d

      # Utilities from the old laptop that need missing scripts/packages:
      # bind = $mod ALT, G, exec, gamemode
      # bind = $mod SHIFT, G, exec, gamelauncher
      # bind = $mod SHIFT, W, exec, wallpaper-selector
      # bind = $mod SHIFT, R, exec, wallbash-mode-selector
      # bind = $mod SHIFT, T, exec, theme-selector
      # bind = ALT_R, Control_R, exec, killall waybar || waybar

      # Workspaces
      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9
      bind = $mod, 0, workspace, 10
      bind = $mod CTRL, right, workspace, r+1
      bind = $mod CTRL, left, workspace, r-1
      bind = $mod CTRL, down, workspace, empty
      bind = $mod, mouse_down, workspace, e+1
      bind = $mod, mouse_up, workspace, e-1

      # Move focused window to workspace
      bind = $mod SHIFT, 1, movetoworkspace, 1
      bind = $mod SHIFT, 2, movetoworkspace, 2
      bind = $mod SHIFT, 3, movetoworkspace, 3
      bind = $mod SHIFT, 4, movetoworkspace, 4
      bind = $mod SHIFT, 5, movetoworkspace, 5
      bind = $mod SHIFT, 6, movetoworkspace, 6
      bind = $mod SHIFT, 7, movetoworkspace, 7
      bind = $mod SHIFT, 8, movetoworkspace, 8
      bind = $mod SHIFT, 9, movetoworkspace, 9
      bind = $mod SHIFT, 0, movetoworkspace, 10
      bind = $mod CTRL ALT, right, movetoworkspace, r+1
      bind = $mod CTRL ALT, left, movetoworkspace, r-1

      # Special workspace / scratchpad
      bind = $mod SHIFT, X, movetoworkspace, special
      bind = $mod ALT, S, movetoworkspacesilent, special
      bind = $mod, S, togglespecialworkspace

      # Move focused window silently
      bind = $mod ALT, 1, movetoworkspacesilent, 1
      bind = $mod ALT, 2, movetoworkspacesilent, 2
      bind = $mod ALT, 3, movetoworkspacesilent, 3
      bind = $mod ALT, 4, movetoworkspacesilent, 4
      bind = $mod ALT, 5, movetoworkspacesilent, 5
      bind = $mod ALT, 6, movetoworkspacesilent, 6
      bind = $mod ALT, 7, movetoworkspacesilent, 7
      bind = $mod ALT, 8, movetoworkspacesilent, 8
      bind = $mod ALT, 9, movetoworkspacesilent, 9
      bind = $mod ALT, 0, movetoworkspacesilent, 10
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withRuby = true;
  };

  xdg.configFile."nvim".source = nvim-config;
  xdg.configFile."caelestia/templates/kitty.conf".text = caelestiaKittyTheme;

  programs.home-manager.enable = true;
}
