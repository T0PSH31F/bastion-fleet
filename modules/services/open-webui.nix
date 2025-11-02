{ config, lib, pkgs, ... }:

with lib;

{
  config = mkIf config.bastion.services.openWebUI.enable {
    services.open-webui = {
      enable = true;
      host = "127.0.0.1";
      port = 8080;
      
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "True";
      };
    };

    # Nginx reverse proxy
    services.nginx.virtualHosts.${config.bastion.services.openWebUI.domain} = {
      forceSSL = true;
      enableACME = true;
      
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };

    # Ensure Ollama is running if Open WebUI is enabled
    bastion.services.ollama.enable = mkDefault true;
  };
}
