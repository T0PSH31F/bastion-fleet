# Jellyfin Service Module
# Implements Jellyfin media server with hardware acceleration support
#
# What is Jellyfin?
# - Free and open-source media server (alternative to Plex/Emby)
# - Streams movies, TV shows, music, photos to any device
# - No subscription fees, no tracking, fully self-hosted
#
# Features:
# - Hardware transcoding (Intel Quick Sync, AMD AMF, NVIDIA NVENC)
# - Mobile apps for iOS and Android
# - Web interface for all platforms
# - Automatic metadata fetching (posters, descriptions, ratings)
#
# Architecture:
# - Jellyfin server (listening on port 8096)
# - Nginx reverse proxy with SSL
# - Hardware acceleration via VA-API (Intel/AMD GPUs)

{ config, lib, pkgs, ... }:

with lib;

{
  # Only apply this configuration if Jellyfin is enabled
  config = mkIf config.bastion.services.jellyfin.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    # Hardware acceleration for video transcoding
    # Significantly reduces CPU usage when streaming
    # Supports Intel Quick Sync and AMD AMF
    hardware.opengl = mkIf config.bastion.services.jellyfin.enableHardwareAccel {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # Add jellyfin user to video/render groups
    # Required for accessing GPU hardware acceleration
    users.users.jellyfin.extraGroups = [ "video" "render" ];

    # Nginx reverse proxy configuration
    # Proxies requests to Jellyfin and handles SSL
    services.nginx.virtualHosts.${config.bastion.services.jellyfin.domain} = {
      forceSSL = true;
      enableACME = true;
      
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Protocol $scheme;
          proxy_set_header X-Forwarded-Host $http_host;
        '';
      };
    };

    # Create media directory with correct permissions
    # Customers will upload their media files here
    systemd.tmpfiles.rules = [
      "d /var/lib/jellyfin/media 0755 jellyfin jellyfin -"
    ];
  };
}
