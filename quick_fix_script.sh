#!/usr/bin/env bash

# Швидке виправлення помилок NixOS конфігурації для Hyprland

set -e

echo "🔧 Виправлення помилок в NixOS конфігурації..."

# Створення резервної копії
BACKUP_FILE="/etc/nixos/configuration.nix.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp /etc/nixos/configuration.nix "$BACKUP_FILE"
echo "✅ Резервна копія створена: $BACKUP_FILE"

# Виправлення конфігурації
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

  # Audio - ВИПРАВЛЕНО (прибрано sound.enable та hardware.pulseaudio)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Graphics - ВИПРАВЛЕНО (замінено hardware.opengl на hardware.graphics)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Hyprland - ВИПРАВЛЕНО (прибрано enableNvidiaPatches)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Environment variables
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # XDG Portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Display Manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Essential services
  services.dbus.enable = true;
  security.polkit.enable = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # User account
  users.users.user = {
    isNormalUser = true;
    description = "User";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "input" ];
    shell = pkgs.fish;
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
    btop
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
    hyprpicker
    
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
    libnotify
    
    # System info
    neofetch
    lshw
    pciutils
    usbutils
  ];

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
  ];

  # Programs
  programs.fish.enable = true;
  programs.dconf.enable = true;
  programs.thunar.enable = true;

  # Services
  services.blueman.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Security
  security.pam.services.swaylock = {};

  # System version - ЗМІНІТЬ на вашу версію NixOS!
  system.stateVersion = "24.05"; # Або "23.11", "24.11"
}
EOF

echo "✅ Конфігурація виправлена!"
echo ""
echo "🔄 Перебудова системи..."
sudo nixos-rebuild switch

echo ""
echo "✅ Готово! Основні виправлення:"
echo "  • Замінено hardware.opengl на hardware.graphics"
echo "  • Прибрано застарілі sound.enable та hardware.pulseaudio.enable"
echo "  • Прибрано enableNvidiaPatches (більше не потрібно)"
echo "  • Додано правильні environment variables"
echo "  • Використано SDDM замість greetd для кращої сумісності"
echo ""
echo "🔄 Перезавантажте систему для завершення:"
echo "   sudo reboot"
EOF
