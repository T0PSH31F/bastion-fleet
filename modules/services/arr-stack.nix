{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.bastion.services.arrStack;
  mediaPath = cfg.mediaPath;
in
{
  config = mkIf cfg.enable {
    # Sonarr (TV shows)
    services.sonarr = mkIf cfg.sonarr {
      enable = true;
      openFirewall = true;
    };

    # Radarr (Movies)
    services.radarr = mkIf cfg.radarr {
      enable = true;
      openFirewall = true;
    };

    # Prowlarr (Indexer manager)
    services.prowlarr = mkIf cfg.prowlarr {
      enable = true;
      openFirewall = true;
    };

    # Bazarr (Subtitles)
    services.bazarr = mkIf cfg.bazarr {
      enable = true;
      openFirewall = true;
    };

    # Lidarr (Music)
    services.lidarr = mkIf cfg.lidarr {
      enable = true;
      openFirewall = true;
    };

    # Shared media directories
    systemd.tmpfiles.rules = [
      "d ${mediaPath} 0775 root media -"
      "d ${mediaPath}/tv 0775 root media -"
      "d ${mediaPath}/movies 0775 root media -"
      "d ${mediaPath}/music 0775 root media -"
      "d ${mediaPath}/downloads 0775 root media -"
    ];

    # Create media group
    users.groups.media = {};

    # Add service users to media group
    users.users = {
      sonarr.extraGroups = mkIf cfg.sonarr [ "media" ];
      radarr.extraGroups = mkIf cfg.radarr [ "media" ];
      prowlarr.extraGroups = mkIf cfg.prowlarr [ "media" ];
      bazarr.extraGroups = mkIf cfg.bazarr [ "media" ];
      lidarr.extraGroups = mkIf cfg.lidarr [ "media" ];
    };

    # Nginx reverse proxies
    services.nginx.virtualHosts = {
      "sonarr.${config.bastion.customer.customDomain or "bastion.local"}" = mkIf cfg.sonarr {
        forceSSL = mkIf (config.bastion.customer.customDomain != null) true;
        enableACME = mkIf (config.bastion.customer.customDomain != null) true;
        locations."/".proxyPass = "http://127.0.0.1:8989";
      };

      "radarr.${config.bastion.customer.customDomain or "bastion.local"}" = mkIf cfg.radarr {
        forceSSL = mkIf (config.bastion.customer.customDomain != null) true;
        enableACME = mkIf (config.bastion.customer.customDomain != null) true;
        locations."/".proxyPass = "http://127.0.0.1:7878";
      };

      "prowlarr.${config.bastion.customer.customDomain or "bastion.local"}" = mkIf cfg.prowlarr {
        forceSSL = mkIf (config.bastion.customer.customDomain != null) true;
        enableACME = mkIf (config.bastion.customer.customDomain != null) true;
        locations."/".proxyPass = "http://127.0.0.1:9696";
      };

      "bazarr.${config.bastion.customer.customDomain or "bastion.local"}" = mkIf cfg.bazarr {
        forceSSL = mkIf (config.bastion.customer.customDomain != null) true;
        enableACME = mkIf (config.bastion.customer.customDomain != null) true;
        locations."/".proxyPass = "http://127.0.0.1:6767";
      };

      "lidarr.${config.bastion.customer.customDomain or "bastion.local"}" = mkIf cfg.lidarr {
        forceSSL = mkIf (config.bastion.customer.customDomain != null) true;
        enableACME = mkIf (config.bastion.customer.customDomain != null) true;
        locations."/".proxyPass = "http://127.0.0.1:8686";
      };
    };
  };
}
