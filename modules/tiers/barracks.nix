{ config, lib, ... }:

with lib;

{
  # Barracks tier: Power user setup
  # All services available
  # Moderate resource limits
  
  config = mkIf (config.bastion.tier == "barracks") {
    # More generous resource limits
    systemd.services = {
      nextcloud-setup.serviceConfig.MemoryMax = mkDefault "4G";
      jellyfin.serviceConfig.MemoryMax = mkDefault "4G";
      immich-server.serviceConfig.MemoryMax = mkDefault "4G";
    };

    # Enable advanced features
    bastion.services = {
      immich.enableML = mkDefault true;
      jellyfin.enableHardwareAccel = mkDefault true;
      ollama.enableGPU = mkDefault true;
    };
  };
}
