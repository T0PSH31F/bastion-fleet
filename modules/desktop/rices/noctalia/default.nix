# Noctalia Shell Rice Module
#
# The minimalist - beautiful lavender aesthetic, multi-compositor support.
#
# Features:
# - Quickshell-based minimal shell
# - Multi-compositor (Hyprland, Niri, Sway)
# - Warm lavender aesthetic
# - Lock screen, power profiles
# - Cava music visualization
# - "Quiet by design" philosophy
#
# Source: https://github.com/noctalia-dev/noctalia-shell
#
# TODO: Implement full Noctalia integration
# This requires:
# 1. Adding noctalia-shell flake input
# 2. Importing home-manager module
# 3. Configuring Quickshell
# 4. Setting up compositor (Hyprland/Niri/Sway)

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.bastion.desktop;
  
in {
  config = mkIf (cfg.enable && cfg.rice == "noctalia") {
    
    # Placeholder implementation
    
    environment.systemPackages = with pkgs; [
      hyprland
    ];
    
    programs.hyprland.enable = true;
    
    home-manager.users.${cfg.user} = { pkgs, ... }: {
      home.file.".config/bastion-notice.txt".text = ''
        Noctalia Shell rice is not yet fully implemented.
        
        To complete the implementation, we need to:
        1. Add noctalia-shell flake input to bastion-fleet
        2. Import the home-manager module
        3. Configure Quickshell and compositor
        
        For now, you have a basic Hyprland setup.
        
        Full implementation coming soon!
      '';
    };
  };
}
