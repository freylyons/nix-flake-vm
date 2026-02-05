{
  description = "Build a given NixOS configuration as an executable VM";

  inputs = {
    myVMconf.url = "./../declare";
  };

  outputs = { self, myVMconf }: 
  {
    packages.x86_64-linux.default = myVMconf.nixosConfigurations.default.config.system.build.vm;
  };
}
