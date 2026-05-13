{ pkgs, qylock, ... }:

let

  #qylock setup
  qylockTheme = "clockwork-orbital";

  qylockClockworkOrbitalTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "qylock-theme-${qylockTheme}";
    version = "unstable";
    src = "${qylock}/themes/clockwork/orbital";

    installPhase = ''
      mkdir -p $out/share/qylock/themes/${qylockTheme}
      cp -r ./* $out/share/qylock/themes/${qylockTheme}/

      sed -i 's/^enableWindup=.*/enableWindup=true/' $out/share/qylock/themes/${qylockTheme}/theme.conf

      mkdir -p $out/share/sddm/themes
      ln -s $out/share/qylock/themes/${qylockTheme} $out/share/sddm/themes/${qylockTheme}
    '';
  };
  
  /* #Qylock quickshell
  qylockLockscreen = pkgs.stdenvNoCC.mkDerivation {
    pname = "qylock-quickshell-lockscreen";
    version = "unstable";
    src = qylock;

    installPhase = ''
      mkdir -p $out/share/qylock
      cp -r quickshell-lockscreen $out/share/qylock/quickshell-lockscreen

      ln -s ${qylock}/themes $out/share/qylock/quickshell-lockscreen/themes_link

      mkdir -p $out/bin

      cat > $out/bin/qylock-lock <<EOF
      #!/usr/bin/env bash

      export QML2_IMPORT_PATH="$out/share/qylock/quickshell-lockscreen/imports:\''${QML2_IMPORT_PATH:-}"
      export QML_XHR_ALLOW_FILE_READ=1

      export QS_THEME="\''${1:-\''${QS_THEME:-${qylockTheme}}}"
      export QS_THEME_PATH="${qylockClockworkOrbitalTheme}/share/qylock/themes/${qylockTheme}"

      killall -9 hyprlock swaylock wlogout 2>/dev/null || true

      exec ${pkgs.quickshell}/bin/quickshell -p "$out/share/qylock/quickshell-lockscreen/lock_shell.qml"
      EOF

      chmod +x $out/bin/qylock-lock
    '';
  };*/
in
{
  # SDDM login theme
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.theme = qylockTheme;

  services.displayManager.sddm.extraPackages = with pkgs; [
    qt6.qtdeclarative
    qt6.qt5compat
    qt6.qtsvg
    qt6.qtmultimedia

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];

# Quickshell lockscreen + runtime deps
  environment.systemPackages = with pkgs; [
    qylockClockworkOrbitalTheme
    # qylockLockscreen

    quickshell
    psmisc # killall

    qt6.qtdeclarative
    qt6.qt5compat
    qt6.qtsvg
    qt6.qtmultimedia

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];
}
