# end-4 (celesrenata port) Rice Module
#
# The modern classic - legendary "illogical-impulse" Material You rice ported to NixOS.
# Beautiful Quickshell-based desktop with dynamic theming and smooth animations.
#
# Features:
# - Material You theming (dynamic colors from wallpapers)
# - Quickshell widgets (bar, launcher, overview, notifications)
# - Smooth animations and transitions
# - Python environment for scripting
# - Matugen for color generation
# - Self-contained and declarative
#
# Dependencies:
# - Hyprland (primary compositor)
# - Quickshell
# - Foot terminal
# - Matugen (Material You color generator)
# - Python environment
#
# Configuration:
# - Component-based system (hyprland, quickshell, audio, etc.)
# - Feature toggles (overview, notifications, media controls)
# - Keybind customization
#
# References:
# - GitHub: https://github.com/celesrenata/end-4-flakes
# - Original: https://github.com/end-4/dots-hyprland
# - Flake: github:celesrenata/end-4-flakes

{ config, lib, pkgs, riceInputs, ... }:

with lib;

let
  cfg = config.bastion.desktop;
  riceEnabled = cfg.enable && cfg.rice == "end-4";
  
  # Get rice inputs from parameter
  end4Input = riceInputs.end-4-flakes;
in
{
  config = mkIf riceEnabled {
    # System-level packages required by end-4
    environment.systemPackages = with pkgs; [
      # Core dependencies
      foot                 # Terminal
      matugen              # Material You color generator
      python3              # Python for scripts
      
      # Fonts
      nerdfonts            # Nerd Fonts
    ];
    
    # Enable Hyprland (end-4's compositor)
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    
    # Home-manager configuration for the desktop user
    home-manager.users.${cfg.user} = { config, pkgs, ... }: {
      # Import end-4 home-manager module from flake
      imports = mkIf (end4Input != null) [
        end4Input.homeModules.default
      ];
      
      # Configure end-4 dots
      programs.dots-hyprland = mkIf (end4Input != null) {
        enable = true;
        
        # Style selection (illogical-impulse is the main style)
        style = "illogical-impulse";
        
        # Component configuration
        components = {
          hyprland = true;      # Hyprland compositor config
          quickshell = true;    # Quickshell widgets
          theming = true;       # Material You theming
          ai = false;           # AI features (Phase 4, not yet stable)
          audio = true;         # Audio controls
        };
        
        # Feature toggles
        features = {
          overview = true;          # Workspace overview
          sidebar = false;          # Sidebar (Phase 4, not yet stable)
          notifications = true;     # Notification center
          mediaControls = true;     # Media player controls
        };
        
        # Keybind configuration
        keybinds = {
          modifier = "SUPER";
          terminal = "foot";
        };
      };
      
      # Additional home-manager configuration
      home.packages = with pkgs; [
        # File manager
        thunar
        
        # Audio control
        pavucontrol
        
        # Media player
        mpv
        
        # Screenshot tool
        grim
        slurp
      ];
      
      # Create wallpapers directory
      home.file."Pictures/Wallpapers/.keep".text = "";
    };
  };
}
