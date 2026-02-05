{ config, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "24.05";

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
  ];
}
