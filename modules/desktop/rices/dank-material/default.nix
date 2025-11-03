# DankMaterialShell Rice Module
#
# The complete shell - all-in-one Material Design 3 desktop for Wayland.
# Replaces waybar, swaylock, swayidle, mako, fuzzel, polkit, and more.
#
# Features:
# - Complete desktop shell (bar, launcher, control center, notifications, lock screen)
# - Dynamic theming (wallpaper-based color schemes with matugen)
# - System monitoring (CPU, RAM, GPU, temps via dgop)
# - Powerful launcher (apps, files, emojis, windows, calculator, commands)
# - Media integration (MPRIS controls, calendar, weather, clipboard history)
# - Plugin system for endless customization
# - Multi-compositor support (Niri, Hyprland, Sway, dwl/MangoWC)
#
# Dependencies:
# - Quickshell (QML/UI layer)
# - dgop (Go backend for system integration)
# - Hyprland/Niri/Sway/dwl (compositor choice)
# - matugen (theming)
# - dsearch (file search)
# - Various system utilities
#
# Configuration:
# - Via home-manager module (programs.dankMaterialShell)
# - Optional features (systemd monitoring, clipboard, VPN widgets)
# - Plugin system
#
# References:
# - GitHub: https://github.com/AvengeMedia/DankMaterialShell
# - Website: https://danklinux.com
# - Plugins: https://plugins.danklinux.com
# - Flake: github:AvengeMedia/DankMaterialShell

{ config, lib, pkgs, riceInputs, ... }:

with lib;

let
  cfg = config.bastion.desktop;
  riceEnabled = cfg.enable && cfg.rice == "dank-material";
  
  # Get rice inputs from parameter
  dankInput = riceInputs.dank-material-shell;
in
{
  config = mkIf riceEnabled {
    # System-level packages required by DankMaterialShell
    environment.systemPackages = with pkgs; [
      # Core dependencies
      matugen              # Material You color generator
      networkmanager       # Network management
      pipewire             # Audio
      wireplumber          # Audio session manager
      
      # Fonts
      material-symbols     # Material Symbols font
      nerdfonts            # Nerd Fonts
    ];
    
    # Enable Hyprland (DMS works best with Hyprland or Niri)
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    
    # Home-manager configuration for the desktop user
    home-manager.users.${cfg.user} = { config, pkgs, ... }: {
      # Import DankMaterialShell home-manager module from flake
      imports = mkIf (dankInput != null) [
        dankInput.homeModules.default
      ];
      
      # Configure DankMaterialShell
      programs.dankMaterialShell = mkIf (dankInput != null) {
        enable = true;
        
        # Enable systemd monitoring widgets (CPU, RAM, GPU, temps)
        enableSystemd = true;
        
        # Enable clipboard history widget with image previews
        enableClipboard = true;
        
        # Enable VPN widget (if customer uses VPN)
        enableVPN = false;
        
        # Additional settings can be configured via DMS CLI
        # or ~/.config/dms/config.json
      };
      
      # Additional home-manager configuration
      home.packages = with pkgs; [
        # Terminal
        foot
        
        # File manager
        thunar
        
        # Audio control
        pavucontrol
        
        # Media player
        mpv
        
        # Screenshot tools
        grim
        slurp
        swappy  # Screenshot annotation
        
        # Calculator (for launcher plugin)
        libqalculate
      ];
      
      # Create wallpapers directory for theming
      home.file."Pictures/Wallpapers/.keep".text = "";
    };
  };
}
