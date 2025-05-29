#!/usr/bin/env bash

# Мінімальна установка Hyprland для NixOS (аналог archinstall)
# Тільки найнеобхідніше для запуску

set -e

echo "🚀 Встановлення мінімального Hyprland..."

# Резервна копія
if [ -f /etc/nixos/configuration.nix ]; then
    sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
    echo "✅ Резервна копія створена"
fi

# Мінімальна конфігурація
sudo tee /etc/nixos/configuration.nix > /dev/null << 'EOF'
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Locale
  time.timeZone = "Europe/Kiev";
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Graphics
  hardware.graphics.enable = true;

  # Hyprland
  programs.hyprland.enable = true;

  # Login manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # User
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
  };

  # Minimal packages
  environment.systemPackages = with pkgs; [
    # Terminal
    foot
    
    # File manager
    pcmanfm
    
    # Browser
    firefox
    
    # Launcher
    fuzzel
    
    # Bar
    waybar
    
    # Screenshots
    grim
    slurp
    
    # Clipboard
    wl-clipboard
    
    # Basic tools
    git
    nano
  ];

  # Enable sudo
  security.sudo.enable = true;

  system.stateVersion = "25.05";
}
EOF

# Базова конфігурація Hyprland
mkdir -p ~/.config/hypr

cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Basic Hyprland config

monitor=,preferred,auto,1

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
    sensitivity = 0
}

general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 5
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

dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Key bindings
$mainMod = SUPER

# Applications
bind = $mainMod, Return, exec, foot
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, pcmanfm
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, fuzzel
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

# Move active window to a workspace
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

# Scroll through existing workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

# Autostart
exec-once = waybar
EOF

# Базова конфігурація Waybar
mkdir -p ~/.config/waybar

cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["pulseaudio", "network", "battery", "clock"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}",
        "format-icons": {
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}"
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": "{essid} ",
        "format-ethernet": "Connected ",
        "format-disconnected": "Disconnected "
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": ["", "", ""]
    }
}
EOF

cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: monospace;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(43, 48, 59, 0.8);
    color: #ffffff;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #ffffff;
}

#workspaces button.active {
    background-color: #64727D;
}

#clock, #battery, #network, #pulseaudio {
    padding: 0 10px;
    color: #ffffff;
}
EOF

echo "🔄 Застосування конфігурації..."
sudo nixos-rebuild switch

echo ""
echo "✅ Мінімальний Hyprland встановлено!"
echo ""
echo "🎮 Базові комбінації клавіш:"
echo "  Super + Enter    - Термінал (foot)"
echo "  Super + R        - Launcher (fuzzel)"
echo "  Super + E        - Файловий менеджер"
echo "  Super + Q        - Закрити вікно"
echo "  Super + 1-9      - Перемикання робочих столів"
echo "  Print            - Скріншот"
echo ""
echo "🔄 Перезавантажте систему:"
echo "   sudo reboot"