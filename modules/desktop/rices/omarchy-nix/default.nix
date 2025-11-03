# Omarchy-nix Rice Module
#
# A complete NixOS + Hyprland setup based on DHH's Omarchy.
# Opinionated, web development focused, with multiple theme options.
#
# Features:
# - Hyprland compositor
# - Multiple themes (Tokyo Night, Kanagawa, Everforest, Catppuccin, Nord, Gruvbox)
# - Wallpaper-based theme generation
# - Web development tools
# - Clean, modern interface
#
# Source: https://github.com/henrysipp/omarchy-nix

{ config, lib, pkgs, riceInputs, ... }:

with lib;

let
  cfg = config.bastion.desktop;
  
  # Omarchy-nix flake input (will be added to bastion-fleet flake.nix)
  # For now, we'll create a placeholder that references the upstream flake
  
in {
  config = mkIf (cfg.enable && cfg.rice == "omarchy-nix") {
    
    # System-level packages required for Omarchy-nix
    environment.systemPackages = with pkgs; [
      # Hyprland and Wayland essentials
      hyprland
      xdg-desktop-portal-hyprland
      
      # Terminal and shell
      kitty
      zsh
      starship
      
      # Development tools (web dev focused)
      git
      neovim
      vscode
      
      # File management
      nautilus
      
      # Utilities
      rofi-wayland
      dunst
      brightnessctl
      playerctl
      
      # Theming
      matugen  # For wallpaper-based theme generation
    ];
    
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    
    # Enable required services
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    };
    
    # Home-manager configuration for the user
    home-manager.users.${cfg.user} = { pkgs, ... }: {
      
      # Import Omarchy-nix home-manager module
      # NOTE: This requires adding omarchy-nix to flake inputs
      # For now, we'll create a basic Hyprland + theme setup
      # and document how to integrate the full Omarchy-nix flake
      
      home.packages = with pkgs; [
        # Additional user-level packages
        firefox
        discord
        spotify
      ];
      
      # Basic Hyprland configuration
      # (Full Omarchy config will be imported from the flake)
      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          # Basic keybinds
          "$mod" = "SUPER";
          
          bind = [
            "$mod, Return, exec, kitty"
            "$mod, Q, killactive"
            "$mod, M, exit"
            "$mod, E, exec, nautilus"
            "$mod, V, togglefloating"
            "$mod, R, exec, rofi -show drun"
            "$mod, P, pseudo"
            "$mod, J, togglesplit"
            
            # Move focus
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"
            
            # Workspaces
            "$mod, 1, workspace, 1"
            "$mod, 2, workspace, 2"
            "$mod, 3, workspace, 3"
            "$mod, 4, workspace, 4"
            "$mod, 5, workspace, 5"
            
            # Move to workspace
            "$mod SHIFT, 1, movetoworkspace, 1"
            "$mod SHIFT, 2, movetoworkspace, 2"
            "$mod SHIFT, 3, movetoworkspace, 3"
            "$mod SHIFT, 4, movetoworkspace, 4"
            "$mod SHIFT, 5, movetoworkspace, 5"
          ];
          
          # Basic appearance
          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "rgba(7aa2f7ee)";  # Tokyo Night blue
            "col.inactive_border" = "rgba(414868aa)";
          };
          
          decoration = {
            rounding = 8;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };
            drop_shadow = true;
            shadow_range = 4;
            shadow_render_power = 3;
          };
          
          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };
        };
      };
      
      # Kitty terminal configuration
      programs.kitty = {
        enable = true;
        theme = "Tokyo Night";
        settings = {
          font_family = "JetBrainsMono Nerd Font";
          font_size = 12;
          background_opacity = "0.95";
        };
      };
      
      # Starship prompt
      programs.starship = {
        enable = true;
        enableZshIntegration = true;
      };
      
      # Zsh shell
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
      };
      
      # Rofi launcher
      programs.rofi = {
        enable = true;
        package = pkgs.rofi-wayland;
        theme = "Arc-Dark";
      };
      
      # Git configuration
      programs.git = {
        enable = true;
        userName = config.bastion.desktop._riceMetadata.name or "Bastion User";
        userEmail = "user@bastion.local";
      };
      
      # Neovim
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
    };
    
    # Set default shell to zsh
    users.users.${cfg.user}.shell = pkgs.zsh;
    programs.zsh.enable = true;
  };
}
