# Bastion Desktop Module
# 
# This module provides a tag-based desktop rice selection system.
# Each rice is completely self-contained in its own module folder.
#
# Usage:
#   bastion.desktop = {
#     enable = true;
#     rice = "omarchy-nix";  # or "caelestia", "end-4", "noctalia", "dank-material", "headless"
#   };

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.bastion.desktop;
  
  # Registry of available rices with metadata
  riceRegistry = {
    caelestia = {
      name = "Caelestia Shell";
      description = "The flagship - most popular Quickshell rice with beautiful design";
      compositor = "hyprland";
      difficulty = "medium-high";
      appeal = "very-high";
    };
    
    end-4 = {
      name = "end-4 (celesrenata port)";
      description = "The modern classic - legendary Material You rice for NixOS";
      compositor = "hyprland";
      difficulty = "low-medium";
      appeal = "very-high";
    };
    
    noctalia = {
      name = "Noctalia Shell";
      description = "The minimalist - beautiful lavender aesthetic, multi-compositor";
      compositor = "multi"; # supports hyprland, niri, sway
      difficulty = "medium";
      appeal = "high";
    };
    
    dank-material = {
      name = "DankMaterialShell";
      description = "The complete shell - all-in-one Material Design 3 desktop";
      compositor = "multi"; # supports hyprland, niri, sway, dwl
      difficulty = "medium-high";
      appeal = "very-high";
    };
    
    omarchy-nix = {
      name = "Omarchy-nix";
      description = "The developer's choice - web dev focused with multiple themes";
      compositor = "hyprland";
      difficulty = "low";
      appeal = "high";
    };
    
    headless = {
      name = "Headless";
      description = "The server - no DE, just essential CLI tools (tmux, neovim)";
      compositor = "none";
      difficulty = "low";
      appeal = "minimal";
    };
  };
  
  # Get the selected rice's metadata
  selectedRice = riceRegistry.${cfg.rice} or (throw "Unknown rice: ${cfg.rice}. Available: ${concatStringsSep ", " (attrNames riceRegistry)}");
  
in {
  options.bastion.desktop = {
    enable = mkEnableOption "Bastion desktop environment";
    
    rice = mkOption {
      type = types.enum (attrNames riceRegistry);
      default = "headless";
      description = ''
        Select the desktop rice to use.
        
        Available rices:
        ${concatStringsSep "\n" (mapAttrsToList (name: meta: "  - ${name}: ${meta.description}") riceRegistry)}
      '';
    };
    
    user = mkOption {
      type = types.str;
      description = "Username for home-manager configuration";
    };
  };
  
  config = mkIf cfg.enable {
    # Import the selected rice module
    # Each rice module is responsible for:
    # 1. Installing all required packages (system-level)
    # 2. Configuring home-manager for the user
    # 3. Setting up the compositor (if applicable)
    # 4. Providing all dotfiles and configurations
    imports = [
      (./rices + "/${cfg.rice}")
    ];
    
    # Pass rice metadata to the rice module
    bastion.desktop._riceMetadata = selectedRice;
    
    # Ensure home-manager is available
    assertions = [
      {
        assertion = config.home-manager != null;
        message = "bastion.desktop requires home-manager to be configured";
      }
    ];
  };
}
