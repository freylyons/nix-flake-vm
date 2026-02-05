{
  description = "A basic NixOS flake, intended to be usable on bare-metal or as a VM config. Lab/Demo use only with current settings";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
    in {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./configuration.nix ];
    };
  };
}
