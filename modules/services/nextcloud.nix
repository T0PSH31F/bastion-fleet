{ config, lib, pkgs, ... }:

with lib;

{
  config = mkIf config.bastion.services.nextcloud.enable {
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

    # PostgreSQL
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [{
        name = "nextcloud";
        ensureDBOwnership = true;
      }];
    };

    # Redis
    services.redis.servers.nextcloud = {
      enable = true;
      port = 6379;
    };

    # Nginx reverse proxy
    services.nginx = {
      enable = true;
      
      virtualHosts.${config.bastion.services.nextcloud.domain} = {
        forceSSL = true;
        enableACME = true;
      };
    };

    # ACME certificates
    security.acme = {
      acceptTerms = true;
      defaults.email = config.bastion.customer.email;
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # Secrets
    sops.secrets."nextcloud/admin-password" = {
      sopsFile = ../../secrets/${config.bastion.customer.id}/secrets.yaml;
      owner = "nextcloud";
    };
  };
}
