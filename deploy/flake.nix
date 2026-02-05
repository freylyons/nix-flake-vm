{
  description = "A very basic flake";

  inputs = {
    myVMconf.url = "./../declare";
  };

  outputs = { self, myVMconf }: 
  {
    packages.x86_64-linux.default = myVMconf.nixosConfigurations.default.config.system.build.vm;
  };
}
