{ self, ... }:

{
  flake = {
    # Export all service modules for reuse
    nixosModules = {
      bastion = import ../modules/bastion;
      nextcloud = import ../modules/services/nextcloud.nix;
      jellyfin = import ../modules/services/jellyfin.nix;
      immich = import ../modules/services/immich.nix;
      arr-stack = import ../modules/services/arr-stack.nix;
      ollama = import ../modules/services/ollama.nix;
      open-webui = import ../modules/services/open-webui.nix;
      
      digital-ark = import ../modules/tiers/digital-ark.nix;
      barracks = import ../modules/tiers/barracks.nix;
      forge = import ../modules/tiers/forge.nix;
    };
  };
}
