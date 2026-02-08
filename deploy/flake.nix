{
  description = "Build a given NixOS configuration as an executable VM";

  inputs = {
    myVMconf.url = "./../declare";
  };

  outputs = { self, myVMconf }: 
  {
    # extend our module tree with VM specific options
    nixosConfigurations.default = myVMconf.nixosConfigurations.default.extendModules {
      modules = [
        # virtualisation
        # this overrides the QEMU options -m, -smp by default, so this is the only way to set these options weirdly
        #
        # // excerpt from function definition @ nixpkgs/nixos/modules/virtualisation/qemu-vm.nix
        # exec ${qemu-common.qemuBinary qemu} \
        #       -name ${config.system.name} \
        #       -m ${toString config.virtualisation.memorySize} \
        #       -smp ${toString config.virtualisation.cores} \
        #       -device virtio-rng-pci \
        #       ${concatStringsSep " " config.virtualisation.qemu.networkingOptions} \
        #       ${
        #         concatStringsSep " \\\n    " (
        #           mapAttrsToList (
        #             tag: share:
        #             "-virtfs local,path=${share.source},security_model=${share.securityModel},mount_tag=${tag}"
        #           ) config.virtualisation.sharedDirectories
        #         )
        #       } \
        #       ${drivesCmdLine config.virtualisation.qemu.drives} \
        #       ${concatStringsSep " \\\n    " config.virtualisation.qemu.options} \
        #       $QEMU_OPTS \
        #       "$@"
        # // end excerpt //
        #
        # You will see a discepancy between the options below and the options referenced above. This is because the 
        # `config.virtualisation` options are not loaded by default into the nixOS module tree. To get around this,
        # we need to wrap them with `virtualisation.vmVariant` or add this module to the imports manually.
        {
          virtualisation.vmVariant = {
            virtualisation = {
              memorySize = 2000; # default: 1024    # adjust these values and open btop in the vm to see them change on rebuild
              cores = 4; # default: 1

              qemu.options = [
                # create 9P virtFS device inside the VM
                "-virtfs local,mount_tag=share-mount,path=$SHARE_DIR,security_model=mapped-xattr"
              ];
            };
          };

          # enable 9P virtIO kernel modules
          boot.kernelParams = [
            "CONFIG_NET_9P=y"
            "CONFIG_NET_9P_VIRTIO=y"
            "CONFIG_9P_FS=y"
            "CONFIG_9P_FS_POSIX_ACL=y"
            "CONFIG_PCI=y"
            "CONFIG_VIRTIO_PCI=y"
          ];

        }
      ];
    };

    # create our executable output which launches the VM from the final configuration defined above
    packages.x86_64-linux.default = self.nixosConfigurations.default.config.system.build.vm;
  };
}
