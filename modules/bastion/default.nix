# Bastion Meta-Module
# This is the core module that defines ALL configuration options for Bastion managed servers.
# Every option here maps 1:1 to a field in the website deployment form.
# 
# Architecture:
# - Website form submits JSON → Configuration generator reads this module
# - Generator creates customer config using these options
# - Customer config imports service modules based on enabled services
#
# Usage in customer config:
#   bastion = {
#     enable = true;
#     tier = "digital-ark";
#     services.nextcloud.enable = true;
#   };

{ config, lib, pkgs, ... }:

with lib;

{
  # Define all Bastion configuration options
  # These options are exposed to customer configurations
  options.bastion = {
    enable = mkEnableOption "Bastion managed server";

    # Customer information (populated by configuration generator)
    # This data comes from the website form submission
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

    # Service tier selection
    # Determines resource limits and available features
    # - digital-ark: 3-5 services, basic features, low resource usage
    # - barracks: All services, advanced features, moderate resources
    # - forge: All services, no limits, full customization
    tier = mkOption {
      type = types.enum [ "digital-ark" "barracks" "forge" ];
      description = "Service tier level";
    };

    # Service toggles (matches deployment form exactly)
    # Each service can be independently enabled/disabled
    # Service-specific options are nested under each service
    services = {
      # Nextcloud: Self-hosted file sync and share (like Dropbox/Google Drive)
      # Includes: Files, Calendar, Contacts, Notes, Tasks
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

      # Jellyfin: Media server for movies, TV shows, music
      # Supports hardware transcoding for efficient streaming
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

      # Immich: Google Photos alternative
      # Features: Photo backup, face recognition, search, sharing
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

      # Arr Stack: Automated media management
      # Sonarr (TV), Radarr (Movies), Prowlarr (Indexers), etc.
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

      # Ollama: Run large language models locally
      # Supports Llama, Mistral, Phi, and many other models
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

      # Open WebUI: ChatGPT-like interface for Ollama
      # Provides a web UI for interacting with local AI models
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

    # Desktop rice selection (decoupled home-manager)
    # Allows customers to get a beautiful desktop environment
    # This is a unique selling point - no other NixOS service offers this!
    # Each rice is self-contained in modules/desktop/rices/<rice-name>/
    desktop = {
      enable = mkEnableOption "Bastion desktop environment";
      
      rice = mkOption {
        type = types.enum [ "caelestia" "end-4" "noctalia" "dank-material" "omarchy-nix" "headless" ];
        default = "headless";
        description = "Desktop rice to use (caelestia, end-4, noctalia, dank-material, omarchy-nix, headless)";
      };

      user = mkOption {
        type = types.str;
        default = "user";
        description = "Username for home-manager desktop configuration";
      };
    };

    # Automated backup configuration
    # Uses restic for encrypted, deduplicated backups
    # Supports S3-compatible storage (AWS, Backblaze B2, Wasabi, etc.)
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

    # Monitoring and alerting configuration
    # Stack: Prometheus (metrics) + Grafana (dashboards) + Loki (logs)
    # Provides real-time visibility into server health
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

  # Configuration implementation
  # This section applies the actual NixOS configuration based on enabled options
  config = mkIf config.bastion.enable {
    # Base system configuration
    # These are applied to ALL Bastion servers regardless of tier
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

    # Dynamically import tier-specific modules
    # Each tier module applies resource limits and feature toggles
    imports = [
      (mkIf (config.bastion.tier == "digital-ark") ../tiers/digital-ark.nix)
      (mkIf (config.bastion.tier == "barracks") ../tiers/barracks.nix)
      (mkIf (config.bastion.tier == "forge") ../tiers/forge.nix)
      
      # Desktop rice module (decoupled home-manager)
      ../desktop
    ];
  };
}
