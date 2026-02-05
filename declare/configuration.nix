{ config, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "24.05";

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
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 2000; # default: 1024    # Adjust these values and open btop in the VM to see them change on rebuild
      cores = 4; # default: 1
    };
  };


  users = {
    users = {
      testUser = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        initialPassword = "1234";
      };

      scriptRunner = {
        isSystemUser = true;
        group = "scriptRunner";
      };
    };

    groups = {
      scriptRunner = {};
    };
  };
  
  environment.systemPackages = with pkgs; [
    lolcat
    cowsay
    neofetch
    btop
  ];
}
