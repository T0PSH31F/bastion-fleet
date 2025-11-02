{
  description = "Bastion - Form-Driven NixOS Fleet Management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    
    # For secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # For home-manager profiles
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, sops-nix, home-manager, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      
      imports = [
        # Import our custom flake modules
        ./flake-modules/customers.nix
        ./flake-modules/services.nix
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixos-anywhere
            sops
            age
            ssh-to-age
            deno  # For configuration generator
            jq
          ];
          
          shellHook = ''
            echo "🏰 Bastion Fleet Development Environment"
            echo "Available commands:"
            echo "  nixos-anywhere - Deploy NixOS to remote machines"
            echo "  sops - Manage secrets"
            echo "  deno - Run configuration generator"
          '';
        };

        # Configuration generator package
        packages.generator = pkgs.writeShellScriptBin "bastion-generate" ''
          ${pkgs.deno}/bin/deno run \
            --allow-read --allow-write --allow-env --allow-run \
            ${./lib/generator/main.ts} "$@"
        '';

        # Deployment helper
        packages.deploy = pkgs.writeShellScriptBin "bastion-deploy" ''
          if [ -z "$1" ]; then
            echo "Usage: bastion-deploy <customer-id>"
            exit 1
          fi
          
          CUSTOMER_ID=$1
          
          echo "🚀 Deploying $CUSTOMER_ID..."
          ${pkgs.nixos-anywhere}/bin/nixos-anywhere \
            --flake .#$CUSTOMER_ID \
            --build-on-remote \
            $(cat customers/$CUSTOMER_ID/ip-address.txt)
        '';
      };

      flake = {
        # NixOS modules that will be used by all customer configurations
        nixosModules = {
          # Base Bastion module with all options
          bastion = import ./modules/bastion;
          
          # Service modules
          nextcloud = import ./modules/services/nextcloud.nix;
          jellyfin = import ./modules/services/jellyfin.nix;
          immich = import ./modules/services/immich.nix;
          arr-stack = import ./modules/services/arr-stack.nix;
          ollama = import ./modules/services/ollama.nix;
          open-webui = import ./modules/services/open-webui.nix;
          
          # Tier modules
          digital-ark = import ./modules/tiers/digital-ark.nix;
          barracks = import ./modules/tiers/barracks.nix;
          forge = import ./modules/tiers/forge.nix;
          
          # Home-manager profiles
          home-profiles = import ./modules/home-manager;
        };
        
        # Customer configurations will be dynamically generated
        # and imported here by the configuration generator
      };
    };
}
