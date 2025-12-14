{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    myVMconf.url = "./../declare";
  };

  outputs = { self, nixpkgs, myVMconf }: 
    let
      system = "x86_64-linux";
      hostname = "myVM";
    in
    {

    packages.${system}.${hostname} = myVMconf.nixosConfigurations.${hostname}.config.system.build.vm;
  };
}
