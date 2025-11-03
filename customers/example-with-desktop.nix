# Example Customer Configuration with Desktop Rice
# 
# This demonstrates how to use the tag-based desktop rice selection system.
# Simply set bastion.desktop.rice to one of the available options!
#
# Available rices:
# - "caelestia"      - The flagship (most popular Quickshell rice)
# - "end-4"          - The modern classic (legendary Material You rice)
# - "noctalia"       - The minimalist (beautiful lavender aesthetic)
# - "dank-material"  - The complete shell (all-in-one Material Design 3)
# - "omarchy-nix"    - The developer's choice (web dev focused)
# - "headless"       - The server (no DE, just CLI tools)

{ config, pkgs, ... }:

{
  imports = [
    # Hardware configuration would go here
    # ./hardware-configuration.nix
    
    # Bastion modules
    ../modules/bastion
  ];

  # Bastion configuration
  bastion = {
    enable = true;
    
    # Customer information
    customer = {
      id = "customer-example";
      email = "example@customer.com";
      fullName = "Example Customer";
      customDomain = "example.bastion.com";
    };
    
    # Service tier
    tier = "barracks";
    
    # Enable services
    services = {
      nextcloud.enable = true;
      jellyfin.enable = true;
      immich.enable = true;
      
      arrStack = {
        enable = true;
        sonarr = true;
        radarr = true;
        prowlarr = true;
      };
      
      ollama = {
        enable = true;
        models = [ "llama3.2" "codellama" ];
      };
      
      openWebUI.enable = true;
    };
    
    # 🎨 DESKTOP RICE SELECTION - Just set the tag!
    desktop = {
      enable = true;
      rice = "omarchy-nix";  # ← Change this to any available rice!
      user = "customer";
    };
    
    # Backup configuration
    backup = {
      enable = true;
      storageType = "customer-s3";
      schedule = "daily";
    };
    
    # Monitoring
    monitoring = {
      enable = true;
      remoteAccess = "ssh-only";
      alertEmail = "example@customer.com";
    };
  };
  
  # User configuration
  users.users.customer = {
    isNormalUser = true;
    description = "Example Customer";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };
  
  # Enable home-manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  
  # Networking
  networking.hostName = "bastion-example";
  networking.networkmanager.enable = true;
  
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
