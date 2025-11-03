# Noctalia Shell Rice Module
#
# The minimalist - beautiful lavender aesthetic with multi-compositor support.
# Sleek and minimal desktop shell thoughtfully crafted for Wayland.
#
# Features:
# - Beautiful minimal design with lavender color scheme
# - Multi-compositor support (Niri, Hyprland, Sway)
# - Quickshell-based widgets
# - Bar, control center, notifications, lock screen
# - Customizable via Nix configuration
# - Active development (970 stars, v2.21.1)
#
# Dependencies:
# - Quickshell (git version)
# - Hyprland/Niri/Sway (compositor choice)
# - Various system utilities
#
# Configuration:
# - Via home-manager module (programs.noctalia-shell)
# - Settings deep merged with defaults
# - Optional custom colors
# - Systemd service for auto-start
#
# References:
# - GitHub: https://github.com/noctalia-dev/noctalia-shell
# - Docs: https://docs.noctalia.dev
# - Flake: github:noctalia-dev/noctalia-shell

{ config, lib, pkgs, riceInputs, ... }:

with lib;

let
  cfg = config.bastion.desktop;
  riceEnabled = cfg.enable && cfg.rice == "noctalia";
  
  # Get rice inputs from parameter
  noctaliaInput = riceInputs.noctalia-shell;
  quickshellInput = riceInputs.quickshell;
in
{
  config = mkIf riceEnabled {
    # System-level packages required by Noctalia
    environment.systemPackages = with pkgs; [
      # Core dependencies
      networkmanager
      pipewire
      wireplumber
      
      # Fonts
      nerdfonts
    ];
    
    # Enable Hyprland (Noctalia's default compositor)
    # Note: Noctalia also supports Niri and Sway
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    
    # Home-manager configuration for the desktop user
    home-manager.users.${cfg.user} = { config, pkgs, ... }: {
      # Import Noctalia home-manager module from flake
      imports = mkIf (noctaliaInput != null) [
        noctaliaInput.homeModules.default
      ];
      
      # Configure Noctalia shell
      programs.noctalia-shell = mkIf (noctaliaInput != null) {
        enable = true;
        
        # Settings configuration (deep merged with defaults)
        settings = {
          # Bar configuration
          bar = {
            density = "comfortable";  # or "compact"
            position = "top";         # or "bottom", "left", "right"
            showCapsule = true;
            
            widgets = {
              left = [
                { id = "SidePanelToggle"; useDistroLogo = true; }
                { id = "Workspace"; hideUnoccupied = false; labelMode = "icon"; }
              ];
              center = [
                { id = "Clock"; formatHorizontal = "HH:mm"; useMonospacedFont = true; }
              ];
              right = [
                { id = "WiFi"; }
                { id = "Bluetooth"; }
                { id = "Battery"; alwaysShowPercentage = false; warningThreshold = 20; }
              ];
            };
          };
          
          # Color scheme
          colorSchemes.predefinedScheme = "Lavender";  # Noctalia's signature color
          
          # General appearance
          general = {
            avatarImage = "~/.face";
            radiusRatio = 0.2;
          };
          
          # Location for weather widget
          location = {
            name = "Your City";
            monthBeforeDay = true;
          };
        };
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
      ];
    };
  };
}
