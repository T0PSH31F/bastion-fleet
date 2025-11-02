/**
 * TypeScript Type Definitions for Bastion Configuration Generator
 * 
 * These types define the exact structure of data coming from the website deployment form.
 * They map 1:1 to the NixOS module options in modules/bastion/default.nix
 * 
 * Flow:
 * 1. Website form collects user input
 * 2. Form data is validated against these types
 * 3. Generator converts typed data to NixOS configuration
 * 4. Configuration is committed to Git
 * 5. GitHub Actions deploys to customer server
 */

/**
 * Complete deployment configuration from website form
 */
export interface DeploymentConfig {
  customer: CustomerInfo;
  hardware: HardwareConfig;
  tier: ServiceTier;
  services: ServicesConfig;
  homeManager?: HomeManagerConfig;
  backup?: BackupConfig;
  monitoring?: MonitoringConfig;
}

/**
 * Customer information (from form Step 1)
 */
export interface CustomerInfo {
  id: string;              // Generated: customer-001, customer-002, etc.
  email: string;           // For SSL certificates and notifications
  fullName: string;        // Display name
  companyName?: string;    // Optional company name
  customDomain?: string;   // Optional custom domain (e.g., myserver.example.com)
}

/**
 * Hardware configuration (from form Step 2)
 */
export interface HardwareConfig {
  deploymentType: "bastion-provided" | "customer-provided";
  
  // If customer-provided:
  ipAddress?: string;           // SSH target IP
  sshPort?: number;             // Default: 22
  architecture?: Architecture;  // Default: x86_64-linux
  sshPublicKey?: string;        // Customer's SSH public key
  
  // If bastion-provided:
  bastionHardware?: {
    model: string;              // e.g., "Intel NUC 13 Pro"
    specs: {
      cpu: string;
      ram: string;
      storage: string;
    };
    shippingAddress?: Address;
  };
}

export type Architecture = "x86_64-linux" | "aarch64-linux";

export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  country: string;
}

/**
 * Service tier selection (from form Step 3)
 */
export type ServiceTier = "digital-ark" | "barracks" | "forge";

/**
 * Services configuration (from form Step 4)
 * Each service can be independently enabled/disabled
 */
export interface ServicesConfig {
  // Core services
  nextcloud?: NextcloudConfig;
  jellyfin?: JellyfinConfig;
  immich?: ImmichConfig;
  
  // Media automation
  arrStack?: ArrStackConfig;
  
  // AI services
  ollama?: OllamaConfig;
  openWebUI?: OpenWebUIConfig;
  
  // Additional services (future)
  homeAssistant?: boolean;
  vaultwarden?: boolean;
  gitea?: boolean;
  paperless?: boolean;
  photoprism?: boolean;
  audiobookshelf?: boolean;
  calibre?: boolean;
}

export interface NextcloudConfig {
  enabled: boolean;
  domain?: string;          // Default: nextcloud.{customDomain}
  storageQuota?: string;    // Default: "100G"
}

export interface JellyfinConfig {
  enabled: boolean;
  domain?: string;              // Default: jellyfin.{customDomain}
  enableHardwareAccel?: boolean; // Default: true
}

export interface ImmichConfig {
  enabled: boolean;
  domain?: string;      // Default: immich.{customDomain}
  enableML?: boolean;   // Default: true (machine learning)
}

export interface ArrStackConfig {
  enabled: boolean;
  sonarr?: boolean;     // TV shows
  radarr?: boolean;     // Movies
  prowlarr?: boolean;   // Indexer manager
  bazarr?: boolean;     // Subtitles
  lidarr?: boolean;     // Music
  mediaPath?: string;   // Default: /var/lib/media
}

export interface OllamaConfig {
  enabled: boolean;
  models?: string[];    // Default: ["llama3.2"]
  enableGPU?: boolean;  // Default: true
}

export interface OpenWebUIConfig {
  enabled: boolean;
  domain?: string;      // Default: chat.{customDomain}
}

/**
 * Home-manager desktop environment configuration (from form Step 5)
 * This is a unique selling point - beautiful desktop environments!
 */
export interface HomeManagerConfig {
  enabled: boolean;
  profile: DesktopProfile;
  username: string;           // Linux username
  colorScheme?: ColorScheme;  // Default: "dark"
}

export type DesktopProfile = 
  | "minimal"           // Basic shell, vim, tmux
  | "end4-hyprland"     // End-4's beautiful Hyprland setup
  | "caelestia"         // GNOME with Caelestia theme
  | "dank-material";    // Material Design 3 for Wayland

export type ColorScheme = "dark" | "light" | "auto";

/**
 * Backup configuration (from form Step 6)
 */
export interface BackupConfig {
  enabled: boolean;
  storageType: BackupStorageType;
  
  // If customer-s3 or customer-b2:
  s3Config?: S3Config;
  
  schedule: BackupSchedule;
  retention: BackupRetention;
}

export type BackupStorageType = 
  | "customer-s3"       // Customer provides S3 credentials
  | "customer-b2"       // Customer provides Backblaze B2 credentials
  | "bastion-managed";  // Bastion manages backup storage (premium)

export interface S3Config {
  endpoint: string;     // e.g., s3.amazonaws.com, s3.us-west-002.backblazeb2.com
  bucket: string;
  accessKey: string;
  secretKey: string;
  region?: string;
}

export type BackupSchedule = "hourly" | "daily" | "weekly";

export interface BackupRetention {
  daily: number;    // Default: 7
  weekly: number;   // Default: 4
  monthly: number;  // Default: 12
}

/**
 * Monitoring configuration (from form Step 7)
 */
export interface MonitoringConfig {
  enabled: boolean;
  remoteAccess: RemoteAccessMethod;
  
  // If tailscale:
  tailscaleAuthKey?: string;
  
  // Alert configuration
  alertEmail?: string;
  alertWebhook?: string;  // For Slack, Discord, etc.
}

export type RemoteAccessMethod = 
  | "ssh-only"      // Most private, manual SSH tunneling
  | "tailscale"     // Easy VPN access
  | "twingate"      // Enterprise VPN
  | "none";         // No remote access

/**
 * Generated secrets for customer deployment
 * These are encrypted with sops-nix before committing to Git
 */
export interface GeneratedSecrets {
  nextcloud?: {
    adminPassword: string;
  };
  database?: {
    postgresPassword: string;
  };
  monitoring?: {
    grafanaAdminPassword: string;
  };
  backup?: {
    resticPassword: string;
  };
}

/**
 * Generator output - files to be created
 */
export interface GeneratorOutput {
  customerId: string;
  files: GeneratedFile[];
  secrets: GeneratedSecrets;
  gitCommitMessage: string;
}

export interface GeneratedFile {
  path: string;         // Relative to repository root
  content: string;      // File contents
  executable?: boolean; // Make file executable
}

/**
 * Deployment status (stored in Supabase)
 */
export interface DeploymentStatus {
  id: string;                   // UUID
  customerId: string;
  status: DeploymentState;
  progress: number;             // 0-100
  message: string;
  logs?: string[];
  createdAt: Date;
  updatedAt: Date;
}

export type DeploymentState = 
  | "pending"           // Waiting to start
  | "generating"        // Generating configuration
  | "committing"        // Committing to Git
  | "deploying"         // Running nixos-anywhere
  | "configuring"       // Applying NixOS configuration
  | "completed"         // Successfully deployed
  | "failed";           // Deployment failed

/**
 * Validation errors
 */
export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

export class ConfigValidationError extends Error {
  constructor(public errors: ValidationError[]) {
    super(`Configuration validation failed: ${errors.length} errors`);
    this.name = "ConfigValidationError";
  }
}
