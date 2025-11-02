{ config, lib, pkgs, ... }:

with lib;

{
  options.bastion = {
    enable = mkEnableOption "Bastion managed server";

    # Customer information
    customer = {
      id = mkOption {
        type = types.str;
        description = "Unique customer identifier (e.g., customer-001)";
      };

      email = mkOption {
        type = types.str;
        description = "Customer email address";
      };

      fullName = mkOption {
        type = types.str;
        description = "Customer full name";
      };

      customDomain = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom domain for services (optional)";
      };
    };

    # Service tier
    tier = mkOption {
      type = types.enum [ "digital-ark" "barracks" "forge" ];
      description = "Service tier level";
    };

    # Service toggles (matches deployment form)
    services = {
      nextcloud = {
        enable = mkEnableOption "Nextcloud file sync and share";
        domain = mkOption {
          type = types.str;
          default = "nextcloud.${config.bastion.customer.customDomain or "bastion.local"}";
          description = "Domain for Nextcloud instance";
        };
        storageQuota = mkOption {
          type = types.str;
          default = "100G";
          description = "Storage quota per user";
        };
      };

      jellyfin = {
        enable = mkEnableOption "Jellyfin media server";
        domain = mkOption {
          type = types.str;
          default = "jellyfin.${config.bastion.customer.customDomain or "bastion.local"}";
          description = "Domain for Jellyfin instance";
        };
        enableHardwareAccel = mkOption {
          type = types.bool;
          default = true;
          description = "Enable hardware acceleration if available";
        };
      };

      immich = {
        enable = mkEnableOption "Immich photo management";
        domain = mkOption {
          type = types.str;
          default = "immich.${config.bastion.customer.customDomain or "bastion.local"}";
          description = "Domain for Immich instance";
        };
        enableML = mkOption {
          type = types.bool;
          default = true;
          description = "Enable machine learning features";
        };
      };

      arrStack = {
        enable = mkEnableOption "Arr media management stack";
        
        sonarr = mkEnableOption "Sonarr (TV shows)";
        radarr = mkEnableOption "Radarr (movies)";
        prowlarr = mkEnableOption "Prowlarr (indexer manager)";
        bazarr = mkEnableOption "Bazarr (subtitles)";
        lidarr = mkEnableOption "Lidarr (music)";
        
        mediaPath = mkOption {
          type = types.str;
          default = "/var/lib/media";
          description = "Base path for media storage";
        };
      };

      ollama = {
        enable = mkEnableOption "Ollama local AI";
        models = mkOption {
          type = types.listOf types.str;
          default = [ "llama3.2" ];
          description = "AI models to pre-install";
        };
        enableGPU = mkOption {
          type = types.bool;
          default = true;
          description = "Enable GPU acceleration if available";
        };
      };

      openWebUI = {
        enable = mkEnableOption "Open WebUI (ChatGPT-like interface)";
        domain = mkOption {
          type = types.str;
          default = "chat.${config.bastion.customer.customDomain or "bastion.local"}";
          description = "Domain for Open WebUI";
        };
      };

      homeAssistant = mkEnableOption "Home Assistant smart home";
      vaultwarden = mkEnableOption "Vaultwarden password manager";
      gitea = mkEnableOption "Gitea Git hosting";
      paperless = mkEnableOption "Paperless-ngx document management";
      photoprism = mkEnableOption "PhotoPrism photo management";
      audiobookshelf = mkEnableOption "Audiobookshelf audiobook server";
      calibre = mkEnableOption "Calibre e-book server";
    };

    # Home-manager profile
    homeManager = {
      enable = mkEnableOption "Desktop environment via home-manager";
      
      profile = mkOption {
        type = types.enum [ "minimal" "end4-hyprland" "caelestia" "dank-material" ];
        default = "minimal";
        description = "Desktop environment profile";
      };

      username = mkOption {
        type = types.str;
        default = "user";
        description = "Username for desktop environment";
      };

      colorScheme = mkOption {
        type = types.enum [ "dark" "light" "auto" ];
        default = "dark";
        description = "Color scheme preference";
      };
    };

    # Backup configuration
    backup = {
      enable = mkEnableOption "Automated backups";
      
      storageType = mkOption {
        type = types.enum [ "customer-s3" "customer-b2" "bastion-managed" ];
        default = "customer-s3";
        description = "Backup storage type";
      };

      s3Config = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            endpoint = mkOption { type = types.str; };
            bucket = mkOption { type = types.str; };
            accessKeyFile = mkOption { type = types.str; };
            secretKeyFile = mkOption { type = types.str; };
          };
        });
        default = null;
        description = "S3-compatible storage configuration";
      };

      schedule = mkOption {
        type = types.enum [ "hourly" "daily" "weekly" ];
        default = "daily";
        description = "Backup schedule";
      };

      retention = {
        daily = mkOption {
          type = types.int;
          default = 7;
          description = "Number of daily backups to keep";
        };
        weekly = mkOption {
          type = types.int;
          default = 4;
          description = "Number of weekly backups to keep";
        };
        monthly = mkOption {
          type = types.int;
          default = 12;
          description = "Number of monthly backups to keep";
        };
      };
    };

    # Monitoring configuration
    monitoring = {
      enable = mkEnableOption "Prometheus + Grafana monitoring";
      
      remoteAccess = mkOption {
        type = types.enum [ "ssh-only" "tailscale" "twingate" "none" ];
        default = "ssh-only";
        description = "Remote access method for monitoring";
      };

      tailscaleAuthKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Tailscale auth key for VPN access";
      };

      alertEmail = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Email for monitoring alerts";
      };

      alertWebhook = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Webhook URL for monitoring alerts";
      };
    };
  };

  config = mkIf config.bastion.enable {
    # Base system configuration
    system.stateVersion = "24.05";
    
    # Enable flakes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    
    # Basic security
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Firewall
    networking.firewall.enable = true;
    
    # Automatic updates
    system.autoUpgrade = {
      enable = true;
      flake = "github:T0PSH31F/bastion-fleet#${config.bastion.customer.id}";
      dates = "weekly";
    };

    # Enable tier-specific modules based on selection
    imports = [
      (mkIf (config.bastion.tier == "digital-ark") ../tiers/digital-ark.nix)
      (mkIf (config.bastion.tier == "barracks") ../tiers/barracks.nix)
      (mkIf (config.bastion.tier == "forge") ../tiers/forge.nix)
    ];
  };
}
