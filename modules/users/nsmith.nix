{
  config,
  pkgs,
  lib,
  ...
}:

{
  users.users.nsmith = {
    isNormalUser = true;
    description = "Nathanael Smith";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}

