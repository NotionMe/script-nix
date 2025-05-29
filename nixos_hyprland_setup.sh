#!/usr/bin/env bash

# NixOS Hyprland Auto Setup Script
# Автоматично налаштовує Hyprland з усіма необхідними компонентами

set -e

echo "🚀 Початок налаштування Hyprland для NixOS..."

# Перевірка чи запущено як root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Не запускайте цей скрипт як root!"
   exit 1
fi

# Створення резервної копії існуючої конфігурації
BACKUP_DIR="$HOME/nixos-backup-$(date +%Y%m%d-%H%M%S)"
if [ -f /etc/nixos/configuration.nix ]; then
    echo "📦 Створення резервної копії конфігурації..."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -r /etc/nixos/* "$BACKUP_DIR/"
    echo "✅ Резервна копія створена в $BACKUP_DIR"
fi

# Створення конфігурації Hyprland
echo "⚙️ Створення конфігурації NixOS з Hyprland..."

sudo tee /etc/nixos/configuration.nix > /dev/null << 'EOF'
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos-hyprland";
  networking.networkmanager.enable = true;

  # Localization
  time.timeZone = "Europe/Kiev";
  i18n.defaultLocale = "uk_UA.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Graphics
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    enableNvidiaPatches = true; # Увімкніть якщо у вас NVIDIA
  };

  # XDG Portal
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Display Manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # Essential services
  services.dbus.enable = true;
  security.polkit.enable = true;

  # User account
  users.users.user = {
    isNormalUser = true;
    description = "User";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Terminal & Shell
    kitty
    fish
    starship
    
    # File managers
    thunar
    ranger
    
    # Browsers
    firefox
    chromium
    
    # Media
    mpv
    imv
    pavucontrol
    
    # Development
    git
    vim
    neovim
    vscode
    
    # Utilities
    wget
    curl
    unzip
    htop
    tree
    
    # Hyprland ecosystem
    waybar
    wofi
    dunst
    swww
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    
    # Themes & fonts
    gtk3
    gtk4
    adwaita-icon-theme
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    
    # Additional tools
    networkmanagerapplet
    blueman
    polkit_gnome
  ];

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  # Programs
  programs.fish.enable = true;
  programs.dconf.enable = true;

  # System version
  system.stateVersion = "23.11";
}
EOF

# Створення конфігурації Hyprland
echo "🎨 Створення конфігурації Hyprland..."

mkdir -p "$HOME/.config/hypr"
cat > "$HOME/.config/hypr/hyprland.conf" << 'EOF'
# Hyprland Configuration

# Monitor configuration
monitor=,preferred,auto,1

# Input configuration
input {
    kb_layout = us,ua
    kb_options = grp:alt_shift_toggle
    
    follow_mouse = 1
    
    touchpad {
        natural_scroll = no
    }
    
    sensitivity = 0
}

# General settings
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    
    layout = dwindle
    
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 10
    
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    
    drop_shadow = yes
    shadow_range = 4
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

# Layout
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Gestures
gestures {
    workspace_swipe = off
}

# Misc
misc {
    force_default_wallpaper = -1
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$

# Key bindings
$mainMod = SUPER

# Applications
bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive, 
bind = $mainMod, M, exit, 
bind = $mainMod, E, exec, thunar
bind = $mainMod, F, togglefloating, 
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
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

# Move windows to workspace
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

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = $mainMod, Print, exec, grim - | wl-copy

# Audio
bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bind = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Autostart
exec-once = waybar
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = swww init
EOF

# Створення конфігурації Waybar
echo "📊 Створення конфігурації Waybar..."

mkdir -p "$HOME/.config/waybar"
cat > "$HOME/.config/waybar/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    
    "modules-left": ["hyprland/workspaces", "hyprland/mode"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "temperature", "battery", "clock", "tray"],
    
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
    
    "battery": {
        "states": {
            "good": 95,
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

cat > "$HOME/.config/waybar/style.css" << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "Font Awesome 5 Free", "FiraCode Nerd Font";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(43, 48, 59, 0.8);
    border-bottom: 3px solid rgba(100, 114, 125, 0.5);
    color: #ffffff;
    transition-property: background-color;
    transition-duration: .5s;
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 0;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #ffffff;
}

#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
}

#workspaces button.focused {
    background-color: #64727D;
    box-shadow: inset 0 -3px #ffffff;
}

#clock,
#battery,
#cpu,
#memory,
#temperature,
#backlight,
#network,
#pulseaudio,
#tray {
    padding: 0 10px;
    color: #ffffff;
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
EOF

# Створення конфігурації Wofi
echo "🔍 Створення конфігурації Wofi..."

mkdir -p "$HOME/.config/wofi"
cat > "$HOME/.config/wofi/config" << 'EOF'
width=600
height=400
location=center
show=drun
prompt=Search...
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=40
gtk_dark=true
EOF

cat > "$HOME/.config/wofi/style.css" << 'EOF'
window {
    margin: 0px;
    border: 1px solid #33ccff;
    background-color: rgba(43, 48, 59, 0.9);
    border-radius: 10px;
}

#input {
    margin: 5px;
    border: none;
    color: #ffffff;
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 5px;
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: transparent;
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: transparent;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    border: none;
    color: #ffffff;
}

#entry:selected {
    background-color: rgba(51, 204, 255, 0.3);
    border-radius: 5px;
}
EOF

# Створення конфігурації Dunst
echo "📢 Створення конфігурації Dunst..."

mkdir -p "$HOME/.config/dunst"
cat > "$HOME/.config/dunst/dunstrc" << 'EOF'
[global]
    monitor = 0
    follow = mouse
    geometry = "300x5-30+20"
    indicate_hidden = yes
    shrink = no
    transparency = 10
    notification_height = 0
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    frame_width = 2
    frame_color = "#33ccff"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = FiraCode Nerd Font 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    max_icon_size = 32
    sticky_history = yes
    history_length = 20
    dmenu = /usr/bin/wofi -p dunst:
    browser = /usr/bin/firefox -new-tab
    always_run_script = true
    title = Dunst
    class = Dunst
    startup_notification = false
    verbosity = mesg

[experimental]
    per_monitor_dpi = false

[shortcuts]
    close = ctrl+space
    close_all = ctrl+shift+space
    history = ctrl+grave
    context = ctrl+shift+period

[urgency_low]
    background = "#2b303b"
    foreground = "#ffffff"
    timeout = 10

[urgency_normal]
    background = "#2b303b"
    foreground = "#ffffff"
    timeout = 10

[urgency_critical]
    background = "#bf616a"
    foreground = "#ffffff"
    frame_color = "#bf616a"
    timeout = 0
EOF

# Створення автостарт скрипта
echo "🚀 Створення автостарт скрипта..."

mkdir -p "$HOME/.config/hypr/scripts"
cat > "$HOME/.config/hypr/scripts/autostart.sh" << 'EOF'
#!/bin/bash

# Hyprland autostart script

# Set wallpaper
swww img ~/Pictures/wallpaper.jpg 2>/dev/null || swww img /usr/share/pixmaps/nixos-logo.png 2>/dev/null

# Start polkit agent
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Start network manager applet
nm-applet --indicator &

# Start bluetooth manager
blueman-applet &

# Start waybar
waybar &

# Start notification daemon
dunst &

sleep 2
echo "Autostart completed"
EOF

chmod +x "$HOME/.config/hypr/scripts/autostart.sh"

# Створення скрипта для швидкого перезапуску
cat > "$HOME/.config/hypr/scripts/restart-hyprland.sh" << 'EOF'
#!/bin/bash

# Restart Hyprland components

killall waybar 2>/dev/null
killall dunst 2>/dev/null

sleep 1

waybar &
dunst &

echo "Hyprland components restarted"
EOF

chmod +x "$HOME/.config/hypr/scripts/restart-hyprland.sh"

# Налаштування Fish shell
echo "🐟 Налаштування Fish shell..."

mkdir -p "$HOME/.config/fish"
cat > "$HOME/.config/fish/config.fish" << 'EOF'
# Fish shell configuration for Hyprland

# Set default editor
set -gx EDITOR nvim

# Starship prompt
starship init fish | source

# Aliases
alias ll 'ls -alF'
alias la 'ls -A'
alias l 'ls -CF'
alias grep 'grep --color=auto'
alias ..  'cd ..'
alias ... 'cd ../..'

# Hyprland specific
alias hrestart '~/.config/hypr/scripts/restart-hyprland.sh'
alias hconfig 'nvim ~/.config/hypr/hyprland.conf'

# Git aliases
alias gs 'git status'
alias ga 'git add'
alias gc 'git commit'
alias gp 'git push'

echo "🎉 Welcome to Hyprland on NixOS!"
EOF

echo "🔧 Застосування конфігурації NixOS..."

# Перебудова системи
echo "⚡ Перебудова NixOS..."
sudo nixos-rebuild switch

echo ""
echo "✅ Налаштування завершено!"
echo ""
echo "📋 Що було зроблено:"
echo "  • Встановлено Hyprland з усіма необхідними компонентами"
echo "  • Налаштовано Waybar, Wofi, Dunst"
echo "  • Створено конфігурації для всіх компонентів"
echo "  • Налаштовано Fish shell з корисними aliases"
echo "  • Додано автостарт скрипти"
echo ""
echo "🎮 Основні комбінації клавіш:"
echo "  • Super + Q     - Відкрити термінал"
echo "  • Super + R     - Відкрити меню додатків"
echo "  • Super + E     - Відкрити файловий менеджер"
echo "  • Super + C     - Закрити вікно"
echo "  • Super + 1-9   - Перемикання робочих столів"
echo "  • Print         - Скріншот області"
echo ""
echo "🔧 Корисні команди:"
echo "  • hrestart      - Перезапустити компоненти Hyprland"
echo "  • hconfig       - Редагувати конфігурацію Hyprland"
echo ""
echo "🔄 Перезавантажте систему для завершення налаштування:"
echo "   sudo reboot"
echo ""
echo "🎉 Насолоджуйтесь Hyprland на NixOS!"
EOF
