{ config, lib, ... }:

with lib;

{
  # Forge tier: Ultimate self-hosting
  # All services, no limits
  # Full customization
  
  config = mkIf (config.bastion.tier == "forge") {
    # No resource limits - customer has dedicated hardware
    
    # Enable all advanced features
    bastion.services = {
      immich.enableML = mkDefault true;
      jellyfin.enableHardwareAccel = mkDefault true;
      ollama.enableGPU = mkDefault true;
    };

    # Enable performance optimizations
    boot.kernel.sysctl = {
      "vm.swappiness" = 10;
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
    };

    # Enable zram for better memory management
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };
  };
}
