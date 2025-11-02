# Bastion Fleet - Form-Driven NixOS Deployment

Automated NixOS deployment system for Bastion managed servers. Generates customer configurations from web form submissions and deploys them automatically.

## Architecture

```
Website Form → API → Generator → Git → GitHub Actions → nixos-anywhere → Customer Server
```

## Repository Structure

```
bastion-fleet/
├── flake.nix                    # Main flake with flake-parts
├── flake.lock
├── modules/
│   ├── bastion/                 # Meta-module with all options
│   │   └── default.nix
│   ├── services/                # Individual service modules
│   │   ├── nextcloud.nix
│   │   ├── jellyfin.nix
│   │   ├── immich.nix
│   │   ├── arr-stack.nix
│   │   ├── ollama.nix
│   │   └── open-webui.nix
│   ├── tiers/                   # Tier-specific configurations
│   │   ├── digital-ark.nix
│   │   ├── barracks.nix
│   │   └── forge.nix
│   └── home-manager/            # Desktop environment profiles
│       ├── minimal.nix
│       ├── end4-hyprland.nix
│       ├── caelestia.nix
│       └── dank-material.nix
├── lib/
│   ├── generator/               # Configuration generator (TypeScript/Deno)
│   │   ├── main.ts
│   │   ├── types.ts
│   │   └── templates.ts
│   └── templates/               # Nix configuration templates
│       ├── customer-base.nix.hbs
│       ├── hardware.nix.hbs
│       └── secrets.yaml.hbs
├── customers/                   # Generated customer configs (gitignored)
│   └── customer-001/
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── secrets.yaml
├── secrets/                     # Encrypted secrets (sops-nix)
│   ├── .sops.yaml
│   └── customer-001/
│       └── secrets.yaml
├── flake-modules/               # Flake-parts modules
│   ├── customers.nix
│   └── services.nix
├── .github/
│   └── workflows/
│       ├── deploy.yml           # Deployment automation
│       └── test.yml             # CI tests
└── docs/                        # Documentation
    ├── architecture.md
    ├── deployment.md
    └── development.md
```

## Service Modules

All service modules are **form-driven** - every option maps to a field in the website deployment builder.

### Available Services

- **Nextcloud**: File sync and share
- **Jellyfin**: Media server
- **Immich**: Photo management
- **Arr Stack**: Media automation (Sonarr, Radarr, Prowlarr, Bazarr, Lidarr)
- **Ollama**: Local AI models
- **Open WebUI**: ChatGPT-like interface for Ollama

### Service Tiers

- **Digital Ark**: 3-5 services, basic features
- **Barracks**: All services, advanced features
- **Forge**: All services, no limits, full customization

## Configuration Generator

The generator takes JSON from the website form and produces:

1. `configuration.nix` - Main NixOS configuration
2. `hardware-configuration.nix` - Hardware-specific settings
3. `secrets.yaml` - Encrypted secrets (passwords, API keys)

### Example Input (from website form):

```json
{
  "customer": {
    "id": "customer-001",
    "email": "user@example.com",
    "fullName": "John Doe"
  },
  "tier": "digital-ark",
  "services": {
    "nextcloud": true,
    "jellyfin": true,
    "immich": false
  },
  "homeManager": {
    "enabled": true,
    "profile": "end4-hyprland",
    "username": "john"
  }
}
```

### Generated Output:

```nix
# customers/customer-001/configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ../../modules/bastion
    ../../modules/services/nextcloud.nix
    ../../modules/services/jellyfin.nix
    ./hardware-configuration.nix
  ];

  bastion = {
    enable = true;
    tier = "digital-ark";
    
    customer = {
      id = "customer-001";
      email = "user@example.com";
      fullName = "John Doe";
    };

    services = {
      nextcloud.enable = true;
      jellyfin.enable = true;
    };

    homeManager = {
      enable = true;
      profile = "end4-hyprland";
      username = "john";
    };
  };
}
```

## Deployment Flow

1. **Customer fills form** on bastionserver.com
2. **Form submits JSON** to `/api/deploy` endpoint
3. **API validates** and calls configuration generator
4. **Generator creates** NixOS configuration files
5. **Generator encrypts** secrets with sops-nix
6. **Generator commits** to Git (customer branch)
7. **GitHub Actions** triggered automatically
8. **nixos-anywhere** deploys to customer server
9. **Status updates** sent to Supabase in real-time
10. **Dashboard shows** deployment progress

## Development

### Setup

```bash
# Clone repository
git clone https://github.com/T0PSH31F/bastion-fleet.git
cd bastion-fleet

# Enter development shell
nix develop

# Install Deno dependencies (for generator)
cd lib/generator
deno cache main.ts
```

### Testing

```bash
# Test configuration generation
bastion-generate test-config.json

# Test deployment to VM
bastion-deploy customer-001
```

### Adding a New Service

1. Create module in `modules/services/your-service.nix`
2. Add options to `modules/bastion/default.nix`
3. Export module in `flake-modules/services.nix`
4. Update generator templates
5. Test in VM

## Secrets Management

Uses **sops-nix** for secret encryption:

```bash
# Generate age key
ssh-to-age < ~/.ssh/id_ed25519.pub

# Create .sops.yaml
cat > .sops.yaml <<EOF
keys:
  - &admin age1...
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *admin
EOF

# Edit secrets
sops secrets/customer-001/secrets.yaml
```

## Integration with Website

The website deployment builder (Phase 6) will submit configurations to this backend.

**API Endpoint**: `POST /api/deploy`

**Request**:
```typescript
{
  userId: string;
  config: DeploymentConfig;
}
```

**Response**:
```typescript
{
  success: boolean;
  deploymentId: string;
  customerId: string;
  message: string;
}
```

See `docs/api.md` for complete API documentation.

## License

Proprietary - Bastion Server

## Support

For issues or questions, contact: support@bastionserver.com
