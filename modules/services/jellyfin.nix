{ config, lib, pkgs, ... }:

with lib;

{
  config = mkIf config.bastion.services.jellyfin.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    # Hardware acceleration (Intel/AMD)
    hardware.opengl = mkIf config.bastion.services.jellyfin.enableHardwareAccel {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # Add jellyfin user to video group for hardware access
    users.users.jellyfin.extraGroups = [ "video" "render" ];

    # Nginx reverse proxy
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

    # Media directory
    systemd.tmpfiles.rules = [
      "d /var/lib/jellyfin/media 0755 jellyfin jellyfin -"
    ];
  };
}
