# Nextcloud Service Module
# Implements a complete Nextcloud installation with PostgreSQL and Redis
#
# What is Nextcloud?
# - Self-hosted file sync and share (like Dropbox/Google Drive)
# - Includes: Files, Calendar, Contacts, Notes, Tasks, Mail
# - Mobile apps available for iOS and Android
#
# Architecture:
# - Nextcloud (PHP application)
# - PostgreSQL (database for metadata)
# - Redis (caching for performance)
# - Nginx (reverse proxy with SSL)
# - ACME (automatic SSL certificates via Let's Encrypt)
#
# Security:
# - Admin password stored in sops-encrypted secrets
# - HTTPS enforced via nginx
# - Database credentials managed by NixOS

{ config, lib, pkgs, ... }:

with lib;

{
  # Only apply this configuration if Nextcloud is enabled
  config = mkIf config.bastion.services.nextcloud.enable {
    # Nextcloud service configuration
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud29;
      
      hostName = config.bastion.services.nextcloud.domain;
      
      config = {
        dbtype = "pgsql";
        adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
        adminuser = "admin";
      };

      database.createLocally = true;
      
      configureRedis = true;
      
      maxUploadSize = "16G";
      
      https = true;
      
      autoUpdateApps.enable = true;
      
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit calendar contacts mail notes tasks;
      };
      
      settings = {
        default_phone_region = "US";
        overwriteprotocol = "https";
      };
    };

    # PostgreSQL database for Nextcloud
    # NixOS automatically creates the database and user
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [{
        name = "nextcloud";
        ensureDBOwnership = true;
      }];
    };

    # Redis for caching (improves performance significantly)
    services.redis.servers.nextcloud = {
      enable = true;
      port = 6379;
    };

    # Nginx reverse proxy with SSL
    # Handles HTTPS termination and forwards to Nextcloud
    services.nginx = {
      enable = true;
      
      virtualHosts.${config.bastion.services.nextcloud.domain} = {
        forceSSL = true;
        enableACME = true;
      };
    };

    # ACME (Let's Encrypt) for automatic SSL certificates
    # Certificates are automatically renewed
    security.acme = {
      acceptTerms = true;
      defaults.email = config.bastion.customer.email;
    };

    # Open firewall ports for HTTP and HTTPS
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # Secrets management via sops-nix
    # Admin password is encrypted and only decrypted on the target server
    sops.secrets."nextcloud/admin-password" = {
      sopsFile = ../../secrets/${config.bastion.customer.id}/secrets.yaml;
      owner = "nextcloud";
    };
  };
}
