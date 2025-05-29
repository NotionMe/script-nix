#!/usr/bin/env bash

# Покращена установка Hyprland для NixOS
# З налаштуванням паролів та додатковими функціями

set -e

echo "🚀 Встановлення мінімального Hyprland..."

# Перевірка запуску від root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Цей скрипт потрібно запускати від root!"
   echo "Використайте: sudo $0"
   exit 1
fi

# Встановлення паролю root
echo "🔐 Встановлення паролю для root..."
while true; do
    echo "Введіть пароль для root:"
    passwd root && break
    echo "❌ Помилка встановлення паролю. Спробуйте ще раз."
done

# Запит імені користувача
echo ""
read -p "📝 Введіть ім'я користувача (за замовчуванням: user): " USERNAME
USERNAME=${USERNAME:-user}

# Встановлення паролю користувача
echo "🔐 Встановлення паролю для користувача $USERNAME..."

# Резервна копія
if [ -f /etc/nixos/configuration.nix ]; then
    cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
    echo "✅ Резервна копія створена"
fi

# Покращена конфігурація
tee /etc/nixos/configuration.nix > /dev/null << EOF
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "nixos-hyprland";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Locale & Time
  time.timeZone = "Europe/Kiev";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "uk_UA.UTF-8";
    LC_IDENTIFICATION = "uk_UA.UTF-8";
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_MONETARY = "uk_UA.UTF-8";
    LC_NAME = "uk_UA.UTF-8";
    LC_NUMERIC = "uk_UA.UTF-8";
    LC_PAPER = "uk_UA.UTF-8";
    LC_TELEPHONE = "uk_UA.UTF-8";
    LC_TIME = "uk_UA.UTF-8";
  };

  # Console settings
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
  };

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Login manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "\${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  # User
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "input" ];
    shell = pkgs.bash;
  };

  # Enable sudo without password for wheel group (временно)
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # SSH (опционально)
  services.openssh = {
    enable = false;  # Змініть на true якщо потрібен SSH
    settings.PasswordAuthentication = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Terminal & Shell
    foot
    kitty
    bash
    fish
    zsh
    
    # File managers
    pcmanfm
    thunar
    
    # Browsers
    firefox
    chromium
    
    # Launchers & Menus
    fuzzel
    rofi-wayland
    
    # Bars & Panels
    waybar
    eww
    
    # Screenshots & Screen recording
    grim
    slurp
    wf-recorder
    
    # Clipboard
    wl-clipboard
    cliphist
    
    # Notifications
    dunst
    libnotify
    
    # Wallpapers
    swaybg
    swww
    
    # Audio control
    pavucontrol
    pulsemixer
    
    # Network
    networkmanagerapplet
    
    # System monitoring
    htop
    btop
    
    # Text editors
    nano
    vim
    neovim
    
    # Development tools
    git
    curl
    wget
    unzip
    zip
    
    # System utilities
    tree
    fd
    ripgrep
    bat
    exa
    
    # Archive tools
    p7zip
    unrar
    
    # Media
    mpv
    imv
    
    # Themes & Icons
    adwaita-icon-theme
    gnome-themes-extra
    
    # Polkit agent
    polkit_gnome
  ];

  # Polkit
  security.polkit.enable = true;

  # Enable programs
  programs.dconf.enable = true;
  programs.thunar.enable = true;

  # Services
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Performance & Power management
  powerManagement.enable = true;
  services.thermald.enable = true;

  system.stateVersion = "25.05";
}
EOF

echo "🔧 Створення конфігурацій користувача..."

# Створюємо домашню директорію користувача якщо її немає
USER_HOME="/home/$USERNAME"
if [ ! -d "$USER_HOME" ]; then
    mkdir -p "$USER_HOME"
    chown $USERNAME:users "$USER_HOME"
fi

# Покращена конфігурація Hyprland
sudo -u $USERNAME mkdir -p "$USER_HOME/.config/hypr"

sudo -u $USERNAME tee "$USER_HOME/.config/hypr/hyprland.conf" > /dev/null << 'EOF'
# Enhanced Hyprland Configuration

# Monitor configuration
monitor=,preferred,auto,1

# Environment variables
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# Input configuration
input {
    kb_layout = us,ua
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    
    touchpad {
        natural_scroll = yes
        disable_while_typing = yes
        tap-to-click = yes
    }
    
    sensitivity = 0
    accel_profile = flat
}

# General settings
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    
    layout = dwindle
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 8
    
    blur {
        enabled = true
        size = 6
        passes = 2
        new_optimizations = true
    }
    
    drop_shadow = yes
    shadow_range = 8
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = yes
    
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layout settings
dwindle {
    pseudotile = yes
    preserve_split = yes
    smart_split = yes
    smart_resizing = yes
}

master {
    new_is_master = true
}

# Gestures
gestures {
    workspace_swipe = on
    workspace_swipe_fingers = 3
}

# Misc settings
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = yes
    disable_splash_rendering = yes
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
}

# Variables
$mainMod = SUPER
$terminal = foot
$fileManager = thunar
$menu = fuzzel

# Key bindings
# Applications
bind = $mainMod, RETURN, exec, $terminal
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, $menu
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, fullscreen,
bind = $mainMod, B, exec, firefox

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move focus with mainMod + hjkl
bind = $mainMod, h, movefocus, l
bind = $mainMod, l, movefocus, r
bind = $mainMod, k, movefocus, u
bind = $mainMod, j, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Example special workspace (scratchpad)
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy
bind = $mainMod, Print, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +'%Y%m%d-%H%M%S').png

# Audio controls
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Brightness controls
bind = , XF86MonBrightnessUp, exec, brightnessctl set 10%+
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Lock screen
bind = $mainMod, L, exec, swaylock

# Window rules
windowrulev2 = float,class:^(pavucontrol)$
windowrulev2 = float,class:^(nm-applet)$
windowrulev2 = float,class:^(blueman-manager)$
windowrulev2 = float,title:^(Picture-in-Picture)$

# Autostart
exec-once = waybar
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = nm-applet --indicator
exec-once = swaybg -i ~/.config/hypr/wallpaper.jpg -m fill
EOF

# Покращена конфігурація Waybar
sudo -u $USERNAME mkdir -p "$USER_HOME/.config/waybar"

sudo -u $USERNAME tee "$USER_HOME/.config/waybar/config" > /dev/null << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 4,
    
    "modules-left": ["hyprland/workspaces", "hyprland/mode", "hyprland/scratchpad"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["idle_inhibitor", "pulseaudio", "network", "cpu", "memory", "temperature", "backlight", "battery", "clock", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}: {icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    
    "hyprland/mode": {
        "format": "<span style=\"italic\">{}</span>"
    },
    
    "hyprland/scratchpad": {
        "format": "{icon} {count}",
        "show-empty": false,
        "format-icons": ["", ""],
        "tooltip": true,
        "tooltip-format": "{app}: {title}"
    },
    
    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
            "activated": "",
            "deactivated": ""
        }
    },
    
    "tray": {
        "spacing": 10
    },
    
    "clock": {
        "timezone": "Europe/Kiev",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%Y-%m-%d}"
    },
    
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    
    "memory": {
        "format": "{}% "
    },
    
    "temperature": {
        "critical-threshold": 80,
        "format": "{temperatureC}°C {icon}",
        "format-icons": ["", "", ""]
    },
    
    "backlight": {
        "format": "{percent}% {icon}",
        "format-icons": ["", "", "", "", "", "", "", "", ""]
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": "{volume}% ",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    }
}
EOF

sudo -u $USERNAME tee "$USER_HOME/.config/waybar/style.css" > /dev/null << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "FiraCode Nerd Font", monospace;
    font-size: 12px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(43, 48, 59, 0.85);
    border-bottom: 3px solid rgba(100, 114, 125, 0.5);
    color: #ffffff;
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 0;
}

button:hover {
    background: inherit;
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #ffffff;
}

#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
}

#workspaces button.active {
    background-color: #64727D;
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}

#mode {
    background-color: #64727D;
    border-bottom: 3px solid #ffffff;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#tray,
#mode,
#idle_inhibitor,
#scratchpad {
    padding: 0 10px;
    color: #ffffff;
}

#window,
#workspaces {
    margin: 0 4px;
}

.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#clock {
    background-color: #64727D;
}

#battery {
    background-color: #ffffff;
    color: #000000;
}

#battery.charging, #battery.plugged {
    color: #ffffff;
    background-color: #26A65B;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

#battery.critical:not(.charging) {
    background-color: #f53c3c;
    color: #ffffff;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

label:focus {
    background-color: #000000;
}

#cpu {
    background-color: #2ecc71;
    color: #000000;
}

#memory {
    background-color: #9b59b6;
}

#disk {
    background-color: #964B00;
}

#backlight {
    background-color: #90b1b1;
}

#network {
    background-color: #2980b9;
}

#network.disconnected {
    background-color: #f53c3c;
}

#pulseaudio {
    background-color: #f1c40f;
    color: #000000;
}

#pulseaudio.muted {
    background-color: #90b1b1;
    color: #2a5c45;
}

#temperature {
    background-color: #f0932b;
}

#temperature.critical {
    background-color: #eb4d4b;
}

#tray {
    background-color: #2980b9;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #eb4d4b;
}

#idle_inhibitor {
    background-color: #2d3748;
}

#idle_inhibitor.activated {
    background-color: #ecf0f1;
    color: #2d3748;
}
EOF

# Конфігурація Fuzzel
sudo -u $USERNAME mkdir -p "$USER_HOME/.config/fuzzel"

sudo -u $USERNAME tee "$USER_HOME/.config/fuzzel/fuzzel.ini" > /dev/null << 'EOF'
[main]
terminal=foot
layer=overlay
font=FiraCode Nerd Font:size=12
prompt= ❯ 
icon-theme=Adwaita
icons=yes
fields=filename,name,generic
password-character=*
filter-desktop=yes
show-actions=yes
launch-prefix=

[colors]
background=2b303bdd
text=c0c5ceff
match=f99157ff
selection=65737eff
selection-text=c0c5ceff
selection-match=f99157ff
border=4c566aff

[border]
width=2
radius=8

[dmenu]
exit-immediately-if-empty=yes
EOF

# Конфігурація Dunst (сповіщення)
sudo -u $USERNAME mkdir -p "$USER_HOME/.config/dunst"

sudo -u $USERNAME tee "$USER_HOME/.config/dunst/dunstrc" > /dev/null << 'EOF'
[global]
    monitor = 0
    follow = mouse
    width = 300
    height = 300
    origin = top-right
    offset = 10x50
    scale = 0
    notification_limit = 0
    
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    
    indicate_hidden = yes
    transparency = 10
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#89b4fa"
    separator_color = frame
    sort = yes
    
    font = FiraCode Nerd Font 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    
    icon_position = left
    min_icon_size = 0
    max_icon_size = 32
    
    sticky_history = yes
    history_length = 20
    
    dmenu = /usr/bin/dmenu -p dunst:
    browser = /usr/bin/xdg-open
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 8
    ignore_dbusclose = false
    
    force_xinerama = false
    
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 10

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 10

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#fab387"
    timeout = 0
EOF

echo "🔄 Застосування конфігурації NixOS..."
nixos-rebuild switch

echo "🔐 Встановлення паролю для користувача $USERNAME..."
while true; do
    echo "Введіть пароль для користувача $USERNAME:"
    passwd $USERNAME && break
    echo "❌ Помилка встановлення паролю. Спробуйте ще раз."
done

# Надання прав на конфігураційні файли
chown -R $USERNAME:users "$USER_HOME/.config"

echo ""
echo "✅ Покращений Hyprland встановлено!"
echo ""
echo "👤 Створено користувача: $USERNAME"
echo "🔐 Паролі встановлено для root та $USERNAME"
echo ""
echo "🎮 Основні комбінації клавіш:"
echo "  Super + Enter        - Термінал (foot)"
echo "  Super + R            - Launcher (fuzzel)"
echo "  Super + E            - Файловий менеджер (thunar)"
echo "  Super + B            - Браузер (firefox)"
echo "  Super + Q            - Закрити вікно"
echo "  Super + F            - Повноекранний режим"
echo "  Super + V            - Плаваюче вікно"
echo "  Super + L            - Заблокувати екран"
echo "  Super + 1-9          - Перемикання робочих столів"
echo "  Super + Shift + 1-9  - Перемістити вікно на робочий стіл"
echo "  Print                - Скріншот області"
echo "  Shift + Print        - Скріншот всього екрану"
echo "  Alt + Shift          - Перемикання розкладки (US/UA)"
echo ""
echo "🔧 Додаткові функції:"
echo "  - Waybar з системною інформацією"
echo "  - Сповіщення (dunst)"
echo "  - Менеджер мережі"
echo "  - Покращені шрифти"
echo "  - Підтримка українського та англійського"
echo ""
echo "🔄 Перезавантажте систему для завершення:"
echo "   reboot"