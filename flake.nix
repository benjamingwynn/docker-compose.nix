
{
  description = "A NixOS module to declaratively manage Docker Compose services";

  inputs = {
    # Define the version of nixpkgs to use for dependencies like docker-compose.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: {
    # This is the primary output: a NixOS module that other systems can import.
    # We give it a descriptive name.
    nixosModules.docker-compose-services = import ./docker-compose.nix;

    # It's also common to provide it as 'default' for convenience.
    nixosModules.default = self.nixosModules.docker-compose-services;
  };
}