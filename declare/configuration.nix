{ config, pkgs, ... }:
{
  # boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "24.05";

  # users
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

  # Locale
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap= "uk";
  
# system packages
  environment.systemPackages = with pkgs; [
    lolcat
    cowsay
    neofetch
    btop
  ];
}
