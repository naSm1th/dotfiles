{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
}
