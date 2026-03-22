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
            };
          };
        }

        # user space networking (for quick local/non-prod use)
        {
          # this config demonstrates how port-forwarding (DNAT) can be set up to access VM resources from `localhost`
          # for actual production networking, it is recommended to use tap devices and set up interfaces, routes, and firewalls
          #
          # this implementation covers a common use case: SSH access to a dev/lab VM
          # combine this with `-daemonize` and `-display none` QEMU options to get a fully headless process

          # forward ports to the host 
          virtualisation.vmVariant = {
            virtualisation.forwardPorts = [
              { from = "host"; host.port = 22; guest.port = 22; }
            ];
          };

          # ssh daemon configuration 
          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "no";
              PasswordAuthentication = true;  # check declare/configuration.nix for the `initialPassword` value. To use key authentication, set this to `false`
                                              # and configure users.users.<name>..openssh.authorizedKeys.keys with your hypervisor's public key
            };
            ports = [ 22 ];
          };
        }


        # virtFS configuration of share directory 
        {
          virtualisation.vmVariant = {
            virtualisation = {
              qemu.options = [
                # create 9P virtFS device inside the VM
                # https://wiki.qemu.org/Documentation/9psetup#Starting_the_Guest_directly
                "-virtfs local,mount_tag=share-mount,path=$SHARE_DIR,security_model=mapped-xattr"
                # Note: we have included the $SHARE_DIR environment variable here, which needs to be passed to the VM executable
                # at runtime to specify the path of the directory to mount into the guest on the host
              ];
              
              # mount the $SHARE_DIR 
              # QEMU docs command: `mount -t 9p -o trans=virtio [mount tag] [mount point] -oversion=9p2000.L`
              # https://wiki.qemu.org/Documentation/9psetup#Mounting_the_shared_path
              fileSystems."/mnt" = {
                fsType = "9p";
                device = "share-mount";
                options = [ "trans=virtio" "version=9p2000.L" ];
              };
            };
          };

          # enable 9P virtIO kernel modules
          # https://wiki.qemu.org/Documentation/9psetup#Preparation
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
