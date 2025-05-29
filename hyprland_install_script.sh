#!/usr/bin/env bash

# Скрипт для встановлення Hyprland на NixOS
# Автор: Assistant
# Версія: 1.0

set -e

echo "🚀 Початок встановлення Hyprland на NixOS..."

# Запит даних користувача
echo "📋 Введіть дані для налаштування:"
read -p "Введіть ім'я користувача: " USERNAME
if [[ -z "$USERNAME" ]]; then
    echo "❌ Помилка: Ім'я користувача не може бути порожнім"
    exit 1
fi

read -s -p "Введіть пароль для користувача: " PASSWORD
echo
if [[ -z "$PASSWORD" ]]; then
    echo "❌ Помилка: Пароль не може бути порожнім"
    exit 1
fi

read -s -p "Підтвердіть пароль: " PASSWORD_CONFIRM
echo
if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
    echo "❌ Помилка: Паролі не співпадають"
    exit 1
fi

# Перевірка чи користувач має права sudo
if ! sudo -n true 2>/dev/null; then
    echo "❌ Помилка: Потрібні sudo права для виконання скрипта"
    exit 1
fi

# Перевірка чи це NixOS
if [[ ! -f /etc/nixos/configuration.nix ]]; then
    echo "❌ Помилка: Цей скрипт призначений тільки для NixOS"
    exit 1
fi

# Створення бекапу поточної конфігурації
echo "📋 Створення бекапу конфігурації..."
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup.$(date +%Y%m%d_%H%M%S)

# Генерація хешу пароля
echo "🔐 Генерація хешу пароля..."
PASSWORD_HASH=$(echo "$PASSWORD" | mkpasswd -s -m sha-512)

# Створення нової конфігурації
echo "⚙️  Створення конфігурації Hyprland..."

cat > /tmp/hyprland_config.nix << EOF
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos-hyprland";
  networking.networkmanager.enable = true;

  # Timezone
  time.timeZone = "Europe/Kiev";

  # Internationalization
  i18n.defaultLocale = "uk_UA.UTF-8";
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

  # XDG Portal
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable sound
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # User account
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
    packages = with pkgs; [
      # Terminal
      kitty
      
      # File manager
      thunar
      
      # Browser
      firefox
      
      # Text editor
      nano
      vim
      
      # System tools
      htop
      git
      
      # Wayland tools
      waybar
      wofi
      swww
      grim
      slurp
      wl-clipboard
      
      # Notifications
      dunst
    ];
    hashedPassword = "$PASSWORD_HASH";
  };

  # Enable automatic login
  services.getty.autologinUser = "$USERNAME";

  # System packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    vim
    nano
    htop
  ];

  # Enable SSH (optional)
  services.openssh.enable = true;

  # Firewall
  networking.firewall.enable = true;

  # This value determines the NixOS release
  system.stateVersion = "24.05";
}
EOF

# Застосування конфігурації
echo "🔄 Застосування конфігурації..."
sudo cp /tmp/hyprland_config.nix /etc/nixos/configuration.nix
sudo rm /tmp/hyprland_config.nix

# Rebuild системи
echo "🔨 Rebuild NixOS..."
sudo nixos-rebuild switch

echo "✅ Встановлення завершено!"
echo "🎉 Hyprland успішно встановлено з користувачем: $USERNAME"
echo "🔄 Перезавантажте систему та оберіть Hyprland в менеджері дисплея"
echo ""
echo "📝 Корисні команди:"
echo "   - Alt + Enter: відкрити термінал (kitty)"
echo "   - Alt + D: відкрити лаунчер (wofi)"
echo "   - Alt + Q: закрити вікно"
echo "   - Alt + F: повноекранний режим"
echo ""
echo "🗂️  Бекап попередньої конфігурації збережено в /etc/nixos/"

read -p "Хочете перезавантажити систему зараз? (y/N): " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    echo "🔄 Перезавантаження..."
    sudo reboot
fi