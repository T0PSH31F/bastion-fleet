{ self, inputs, ... }:

{
  flake = {
    # This will be populated by the configuration generator
    # Each customer gets a nixosConfiguration
    
    # Example structure (generated automatically):
    # nixosConfigurations = {
    #   customer-001 = inputs.nixpkgs.lib.nixosSystem {
    #     system = "x86_64-linux";
    #     modules = [
    #       inputs.sops-nix.nixosModules.sops
    #       self.nixosModules.bastion
    #       ./customers/customer-001/configuration.nix
    #       ./customers/customer-001/hardware-configuration.nix
    #     ];
    #   };
    # };
  };
}
