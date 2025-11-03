# Caelestia Shell Rice Module
#
# The flagship desktop rice with 5.6k stars - most popular Quickshell-based shell.
# Beautiful, polished interface with Material You theming and extensive customization.
#
# Features:
# - Complete desktop shell (bar, launcher, dashboard, notifications, lock screen)
# - Material You dynamic theming from wallpapers
# - Extensive widget system (workspaces, system stats, media controls)
# - Multi-monitor support
# - Idle management and session controls
# - CLI for IPC and configuration
#
# Dependencies:
# - Hyprland (primary compositor)
# - Quickshell (git version required!)
# - caelestia-cli for full functionality
# - Various system utilities (ddcutil, brightnessctl, etc.)
#
# Configuration:
# - Settings via ~/.config/caelestia/shell.json
# - Wallpapers from ~/Pictures/Wallpapers
# - Profile picture from ~/.face
#
# References:
# - GitHub: https://github.com/caelestia-dots/shell
# - Flake: github:caelestia-dots/shell

{ config, lib, pkgs, riceInputs, ... }:

with lib;

let
  cfg = config.bastion.desktop;
  riceEnabled = cfg.enable && cfg.rice == "caelestia";
  
  # Get rice inputs from parameter
  caelestiaInput = riceInputs.caelestia-shell;
in
{
  config = mkIf riceEnabled {
    # System-level packages required by Caelestia
    environment.systemPackages = with pkgs; [
      # Core dependencies
      ddcutil              # Display control
      brightnessctl        # Brightness control
      app2unit             # Application systemd integration
      networkmanager       # Network management
      lm_sensors           # Hardware sensors
      fish                 # Fish shell (used by some components)
      aubio                # Audio analysis
      swappy               # Screenshot annotation
      libqalculate         # Calculator backend
      
      # Fonts (required for proper display)
      material-symbols     # Material Symbols font
      (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
    ];
    
    # Enable Hyprland (Caelestia's primary compositor)
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    
    # Home-manager configuration for the desktop user
    home-manager.users.${cfg.user} = { config, pkgs, ... }: {
      # Import Caelestia home-manager module from flake
      imports = mkIf (caelestiaInput != null) [
        caelestiaInput.homeModules.default
      ];
      
      # Configure Caelestia shell
      programs.caelestia = mkIf (caelestiaInput != null) {
        enable = true;
        
        # Enable systemd service for auto-start
        systemd = {
          enable = true;
          target = "graphical-session.target";
        };
        
        # Enable CLI for full functionality
        cli = {
          enable = true;
          settings = {
            theme.enableGtk = true;  # Auto-theme GTK apps
          };
        };
        
        # Caelestia settings (deep merged with defaults)
        settings = {
          # Bar configuration
          bar = {
            persistent = true;
            showOnHover = false;
            position = "top";
            
            # Status icons to show
            status = {
              showAudio = true;
              showBattery = true;
              showBluetooth = true;
              showKbLayout = false;
              showMicrophone = false;
              showNetwork = true;
              showLockStatus = true;
            };
            
            # Workspace configuration
            workspaces = {
              activeIndicator = true;
              occupiedBg = true;
              showWindows = true;
              perMonitorWorkspaces = true;
            };
          };
          
          # General appearance
          appearance = {
            transparency = {
              enabled = true;
              base = 0.9;
              layers = 0.5;
            };
            rounding.scale = 1.0;
            padding.scale = 1.0;
          };
          
          # Paths
          paths = {
            wallpaperDir = "~/Pictures/Wallpapers";
          };
          
          # Services configuration
          services = {
            audioIncrement = 0.05;
            maxVolume = 1.0;
            smartScheme = true;  # Auto-generate color schemes from wallpaper
            useTwelveHourClock = false;
          };
          
          # Idle and lock settings
          general.idle = {
            lockBeforeSleep = true;
            inhibitWhenAudio = true;
            timeouts = [
              {
                timeout = 300;  # 5 minutes
                idleAction = "lock";
              }
              {
                timeout = 600;  # 10 minutes
                idleAction = "dpms off";
                returnAction = "dpms on";
              }
            ];
          };
          
          # Launcher configuration
          launcher = {
            maxShown = 8;
            vimKeybinds = false;
            enableDangerousActions = false;  # Disable shutdown/reboot from launcher
          };
          
          # Notification settings
          notifs = {
            actionOnClick = true;
            expire = true;
            defaultExpireTimeout = 5000;
          };
        };
      };
      
      # Additional home-manager configuration
      home.packages = with pkgs; [
        # Terminal (referenced in Caelestia config)
        foot
        
        # File manager
        thunar
        
        # Audio control
        pavucontrol
        
        # Media player
        mpv
      ];
      
      # Create wallpapers directory
      home.file."Pictures/Wallpapers/.keep".text = "";
    };
  };
}
