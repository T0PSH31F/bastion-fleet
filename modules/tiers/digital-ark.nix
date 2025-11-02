{ config, lib, ... }:

with lib;

{
  # Digital Ark tier: Basic self-hosting essentials
  # Recommended services: Nextcloud, Jellyfin, Immich
  # Max 3-5 services
  
  config = mkIf (config.bastion.tier == "digital-ark") {
    # Resource limits
    systemd.services = {
      # Limit resource usage for Digital Ark tier
      nextcloud-setup.serviceConfig.MemoryMax = mkDefault "2G";
      jellyfin.serviceConfig.MemoryMax = mkDefault "2G";
      immich-server.serviceConfig.MemoryMax = mkDefault "2G";
    };

    # Disable some advanced features for this tier
    bastion.services = {
      immich.enableML = mkDefault false;  # ML requires more resources
    };

    # Warnings if too many services enabled
    warnings = 
      let
        enabledServices = count (s: s) [
          config.bastion.services.nextcloud.enable
          config.bastion.services.jellyfin.enable
          config.bastion.services.immich.enable
          config.bastion.services.arrStack.enable
          config.bastion.services.ollama.enable
        ];
      in
        optional (enabledServices > 5) 
          "Digital Ark tier: You have ${toString enabledServices} services enabled. Consider upgrading to Barracks tier for better performance.";
  };
}
