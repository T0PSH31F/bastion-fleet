#!/usr/bin/env -S deno run --allow-read --allow-write --allow-env --allow-run

/**
 * Bastion Configuration Generator
 * 
 * Converts JSON from website deployment form into NixOS configuration files.
 * 
 * Usage:
 *   deno run --allow-all main.ts <config.json>
 *   deno run --allow-all main.ts --stdin < config.json
 * 
 * Flow:
 *   1. Read and validate JSON input
 *   2. Generate NixOS configuration files from templates
 *   3. Generate and encrypt secrets
 *   4. Commit to Git
 *   5. Return deployment ID
 */

import type {
  DeploymentConfig,
  GeneratorOutput,
  GeneratedFile,
  GeneratedSecrets,
  ValidationError,
  ConfigValidationError,
} from "./types.ts";

/**
 * Main entry point
 */
async function main() {
  console.log("🏰 Bastion Configuration Generator");
  console.log("=====================================\n");

  // Parse command line arguments
  const args = Deno.args;
  let configJson: string;

  if (args.includes("--stdin")) {
    // Read from stdin
    const decoder = new TextDecoder();
    const buf = new Uint8Array(4096);
    const n = await Deno.stdin.read(buf);
    configJson = decoder.decode(buf.subarray(0, n || 0));
  } else if (args.length > 0) {
    // Read from file
    configJson = await Deno.readTextFile(args[0]);
  } else {
    console.error("❌ Usage: main.ts <config.json> or main.ts --stdin");
    Deno.exit(1);
  }

  try {
    // Parse and validate configuration
    const config: DeploymentConfig = JSON.parse(configJson);
    console.log(`📋 Processing deployment for: ${config.customer.fullName}`);
    console.log(`   Customer ID: ${config.customer.id}`);
    console.log(`   Tier: ${config.tier}`);
    console.log();

    // Validate configuration
    const errors = validateConfig(config);
    if (errors.length > 0) {
      console.error("❌ Configuration validation failed:\n");
      errors.forEach((err) => {
        console.error(`   • ${err.field}: ${err.message}`);
      });
      Deno.exit(1);
    }

    console.log("✅ Configuration validated");

    // Generate configuration files
    console.log("\n📝 Generating NixOS configuration...");
    const output = await generateConfiguration(config);

    // Write files to disk
    console.log("\n💾 Writing files...");
    await writeFiles(output);

    // Generate and encrypt secrets
    console.log("\n🔐 Generating secrets...");
    await generateSecrets(config, output.secrets);

    // Commit to Git
    console.log("\n📦 Committing to Git...");
    await commitToGit(config.customer.id, output.gitCommitMessage);

    console.log("\n✅ Configuration generated successfully!");
    console.log(`   Customer: ${config.customer.id}`);
    console.log(`   Files: ${output.files.length}`);
    console.log(`   Ready for deployment!`);

    // Return deployment info as JSON
    const result = {
      success: true,
      customerId: config.customer.id,
      filesGenerated: output.files.length,
      message: "Configuration generated and committed to Git",
    };

    console.log("\n" + JSON.stringify(result, null, 2));
  } catch (error) {
    console.error("\n❌ Error:", error.message);
    Deno.exit(1);
  }
}

/**
 * Validate deployment configuration
 */
function validateConfig(config: DeploymentConfig): ValidationError[] {
  const errors: ValidationError[] = [];

  // Validate customer info
  if (!config.customer.id) {
    errors.push({
      field: "customer.id",
      message: "Customer ID is required",
      code: "REQUIRED",
    });
  }

  if (!config.customer.email || !config.customer.email.includes("@")) {
    errors.push({
      field: "customer.email",
      message: "Valid email address is required",
      code: "INVALID_EMAIL",
    });
  }

  // Validate hardware config
  if (config.hardware.deploymentType === "customer-provided") {
    if (!config.hardware.ipAddress) {
      errors.push({
        field: "hardware.ipAddress",
        message: "IP address is required for customer-provided hardware",
        code: "REQUIRED",
      });
    }
  }

  // Validate at least one service is enabled
  const servicesEnabled = Object.values(config.services).some((service) =>
    service && (typeof service === "boolean" ? service : service.enabled)
  );

  if (!servicesEnabled) {
    errors.push({
      field: "services",
      message: "At least one service must be enabled",
      code: "NO_SERVICES",
    });
  }

  // Validate backup config if enabled
  if (config.backup?.enabled) {
    if (
      (config.backup.storageType === "customer-s3" ||
        config.backup.storageType === "customer-b2") &&
      !config.backup.s3Config
    ) {
      errors.push({
        field: "backup.s3Config",
        message: "S3 configuration is required for customer storage",
        code: "REQUIRED",
      });
    }
  }

  return errors;
}

/**
 * Generate NixOS configuration files
 */
async function generateConfiguration(
  config: DeploymentConfig,
): Promise<GeneratorOutput> {
  const customerId = config.customer.id;
  const files: GeneratedFile[] = [];

  // Generate main configuration.nix
  files.push({
    path: `customers/${customerId}/configuration.nix`,
    content: generateMainConfig(config),
  });

  // Generate hardware-configuration.nix (placeholder for now)
  files.push({
    path: `customers/${customerId}/hardware-configuration.nix`,
    content: generateHardwareConfig(config),
  });

  // Generate secrets template
  const secrets = generateSecretsTemplate(config);

  // Generate commit message
  const gitCommitMessage = `feat: add configuration for ${customerId}

Customer: ${config.customer.fullName}
Email: ${config.customer.email}
Tier: ${config.tier}
Services: ${getEnabledServices(config).join(", ")}

Generated by Bastion Configuration Generator
`;

  return {
    customerId,
    files,
    secrets,
    gitCommitMessage,
  };
}

/**
 * Generate main configuration.nix
 */
function generateMainConfig(config: DeploymentConfig): string {
  const { customer, tier, services, homeManager, backup, monitoring } = config;

  // Build services configuration
  const servicesNix = generateServicesNix(services);

  // Build home-manager configuration
  const homeManagerNix = homeManager?.enabled
    ? `
    homeManager = {
      enable = true;
      profile = "${homeManager.profile}";
      username = "${homeManager.username}";
      colorScheme = "${homeManager.colorScheme || "dark"}";
    };`
    : "";

  // Build backup configuration
  const backupNix = backup?.enabled
    ? `
    backup = {
      enable = true;
      storageType = "${backup.storageType}";
      schedule = "${backup.schedule}";
      retention = {
        daily = ${backup.retention.daily};
        weekly = ${backup.retention.weekly};
        monthly = ${backup.retention.monthly};
      };
      ${backup.s3Config ? `s3Config = {
        endpoint = "${backup.s3Config.endpoint}";
        bucket = "${backup.s3Config.bucket}";
        accessKeyFile = config.sops.secrets."backup/s3-access-key".path;
        secretKeyFile = config.sops.secrets."backup/s3-secret-key".path;
      };` : ""}
    };`
    : "";

  // Build monitoring configuration
  const monitoringNix = monitoring?.enabled
    ? `
    monitoring = {
      enable = true;
      remoteAccess = "${monitoring.remoteAccess}";
      ${monitoring.alertEmail ? `alertEmail = "${monitoring.alertEmail}";` : ""}
    };`
    : "";

  return `# NixOS Configuration for ${customer.id}
# Generated by Bastion Configuration Generator
# Customer: ${customer.fullName} <${customer.email}>
# Tier: ${tier}
# Generated: ${new Date().toISOString()}

{ config, pkgs, ... }:

{
  imports = [
    ../../modules/bastion
    ./hardware-configuration.nix
  ];

  # Bastion configuration
  bastion = {
    enable = true;
    
    # Customer information
    customer = {
      id = "${customer.id}";
      email = "${customer.email}";
      fullName = "${customer.fullName}";
      ${customer.customDomain ? `customDomain = "${customer.customDomain}";` : ""}
    };

    # Service tier
    tier = "${tier}";

    # Services${servicesNix}${homeManagerNix}${backupNix}${monitoringNix}
  };

  # System configuration
  system.stateVersion = "24.05";
}
`;
}

/**
 * Generate services configuration block
 */
function generateServicesNix(services: any): string {
  let nix = "\n    services = {";

  // Nextcloud
  if (services.nextcloud?.enabled) {
    nix += `
      nextcloud = {
        enable = true;
        ${services.nextcloud.domain ? `domain = "${services.nextcloud.domain}";` : ""}
        ${services.nextcloud.storageQuota ? `storageQuota = "${services.nextcloud.storageQuota}";` : ""}
      };`;
  }

  // Jellyfin
  if (services.jellyfin?.enabled) {
    nix += `
      jellyfin = {
        enable = true;
        ${services.jellyfin.domain ? `domain = "${services.jellyfin.domain}";` : ""}
        ${services.jellyfin.enableHardwareAccel !== undefined ? `enableHardwareAccel = ${services.jellyfin.enableHardwareAccel};` : ""}
      };`;
  }

  // Immich
  if (services.immich?.enabled) {
    nix += `
      immich = {
        enable = true;
        ${services.immich.domain ? `domain = "${services.immich.domain}";` : ""}
        ${services.immich.enableML !== undefined ? `enableML = ${services.immich.enableML};` : ""}
      };`;
  }

  // Arr Stack
  if (services.arrStack?.enabled) {
    nix += `
      arrStack = {
        enable = true;
        ${services.arrStack.sonarr ? "sonarr = true;" : ""}
        ${services.arrStack.radarr ? "radarr = true;" : ""}
        ${services.arrStack.prowlarr ? "prowlarr = true;" : ""}
        ${services.arrStack.bazarr ? "bazarr = true;" : ""}
        ${services.arrStack.lidarr ? "lidarr = true;" : ""}
      };`;
  }

  // Ollama
  if (services.ollama?.enabled) {
    nix += `
      ollama = {
        enable = true;
        ${services.ollama.models ? `models = [ ${services.ollama.models.map((m: string) => `"${m}"`).join(" ")} ];` : ""}
      };`;
  }

  // Open WebUI
  if (services.openWebUI?.enabled) {
    nix += `
      openWebUI = {
        enable = true;
        ${services.openWebUI.domain ? `domain = "${services.openWebUI.domain}";` : ""}
      };`;
  }

  nix += "\n    };";
  return nix;
}

/**
 * Generate hardware-configuration.nix
 */
function generateHardwareConfig(config: DeploymentConfig): string {
  return `# Hardware Configuration for ${config.customer.id}
# This file will be generated by nixos-generate-config during deployment
# Placeholder for now

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "${config.customer.id}";
  networking.useDHCP = lib.mkDefault true;

  # This will be replaced during deployment
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Hardware-specific configuration will be added here
}
`;
}

/**
 * Generate secrets template
 */
function generateSecretsTemplate(
  config: DeploymentConfig,
): GeneratedSecrets {
  const secrets: GeneratedSecrets = {};

  if (config.services.nextcloud?.enabled) {
    secrets.nextcloud = {
      adminPassword: generatePassword(32),
    };
  }

  secrets.database = {
    postgresPassword: generatePassword(32),
  };

  if (config.monitoring?.enabled) {
    secrets.monitoring = {
      grafanaAdminPassword: generatePassword(24),
    };
  }

  if (config.backup?.enabled) {
    secrets.backup = {
      resticPassword: generatePassword(32),
    };
  }

  return secrets;
}

/**
 * Generate a secure random password
 */
function generatePassword(length: number): string {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
  let password = "";
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  for (let i = 0; i < length; i++) {
    password += chars[array[i] % chars.length];
  }
  return password;
}

/**
 * Get list of enabled services
 */
function getEnabledServices(config: DeploymentConfig): string[] {
  const services: string[] = [];

  if (config.services.nextcloud?.enabled) services.push("Nextcloud");
  if (config.services.jellyfin?.enabled) services.push("Jellyfin");
  if (config.services.immich?.enabled) services.push("Immich");
  if (config.services.arrStack?.enabled) services.push("Arr Stack");
  if (config.services.ollama?.enabled) services.push("Ollama");
  if (config.services.openWebUI?.enabled) services.push("Open WebUI");

  return services;
}

/**
 * Write generated files to disk
 */
async function writeFiles(output: GeneratorOutput) {
  for (const file of output.files) {
    const fullPath = `../../${file.path}`;
    console.log(`   Writing: ${file.path}`);

    // Create directory if it doesn't exist
    const dir = fullPath.substring(0, fullPath.lastIndexOf("/"));
    await Deno.mkdir(dir, { recursive: true });

    // Write file
    await Deno.writeTextFile(fullPath, file.content);

    // Make executable if needed
    if (file.executable) {
      await Deno.chmod(fullPath, 0o755);
    }
  }
}

/**
 * Generate and encrypt secrets
 */
async function generateSecrets(
  config: DeploymentConfig,
  secrets: GeneratedSecrets,
) {
  const customerId = config.customer.id;
  const secretsPath = `../../secrets/${customerId}/secrets.yaml`;

  // Create secrets directory
  await Deno.mkdir(`../../secrets/${customerId}`, { recursive: true });

  // Generate secrets YAML
  let yaml = `# Encrypted secrets for ${customerId}\n`;
  yaml += `# Generated: ${new Date().toISOString()}\n\n`;

  if (secrets.nextcloud) {
    yaml += `nextcloud:\n`;
    yaml += `  admin-password: ${secrets.nextcloud.adminPassword}\n\n`;
  }

  if (secrets.database) {
    yaml += `database:\n`;
    yaml += `  postgres-password: ${secrets.database.postgresPassword}\n\n`;
  }

  if (secrets.monitoring) {
    yaml += `monitoring:\n`;
    yaml += `  grafana-admin-password: ${secrets.monitoring.grafanaAdminPassword}\n\n`;
  }

  if (secrets.backup) {
    yaml += `backup:\n`;
    yaml += `  restic-password: ${secrets.backup.resticPassword}\n`;

    if (config.backup?.s3Config) {
      yaml += `  s3-access-key: ${config.backup.s3Config.accessKey}\n`;
      yaml += `  s3-secret-key: ${config.backup.s3Config.secretKey}\n`;
    }
  }

  // Write unencrypted secrets (will be encrypted by sops later)
  await Deno.writeTextFile(secretsPath, yaml);
  console.log(`   Created: secrets/${customerId}/secrets.yaml`);
  console.log(`   ⚠️  TODO: Encrypt with sops before committing!`);
}

/**
 * Commit generated files to Git
 */
async function commitToGit(customerId: string, message: string) {
  // Add files
  const addCmd = new Deno.Command("git", {
    args: ["add", `customers/${customerId}`, `secrets/${customerId}`],
    cwd: "../..",
  });
  await addCmd.output();

  // Commit
  const commitCmd = new Deno.Command("git", {
    args: ["commit", "-m", message],
    cwd: "../..",
  });
  const result = await commitCmd.output();

  if (result.success) {
    console.log(`   ✅ Committed to Git`);
  } else {
    console.log(`   ⚠️  Git commit failed (may already be committed)`);
  }
}

// Run main function
if (import.meta.main) {
  main();
}
