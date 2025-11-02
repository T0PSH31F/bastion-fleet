{ config, lib, pkgs, ... }:

with lib;

{
  config = mkIf config.bastion.services.immich.enable {
    services.immich = {
      enable = true;
      host = "127.0.0.1";
      port = 3001;
      
      environment = {
        IMMICH_MACHINE_LEARNING_ENABLED = toString config.bastion.services.immich.enableML;
      };
    };

    # PostgreSQL for Immich
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "immich" ];
      ensureUsers = [{
        name = "immich";
        ensureDBOwnership = true;
      }];
    };

    # Redis for Immich
    services.redis.servers.immich = {
      enable = true;
      port = 6380;
    };

    # Nginx reverse proxy
    services.nginx.virtualHosts.${config.bastion.services.immich.domain} = {
      forceSSL = true;
      enableACME = true;
      
      locations."/" = {
        proxyPass = "http://127.0.0.1:3001";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };
}
