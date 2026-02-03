# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "pussinboots";
  
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "America/Chicago";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  nixpkgs.config.allowUnfree = true;

  users.groups.media = { };
  users.users.media = {
    isNormalUser = true;
    createHome = false;
    group = "media";
    extraGroups = [ "networkmanager" ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    smartmontools
    e2fsprogs
    wireguard-tools
    pciutils
    usbutils
    dvb-apps
    w_scan2
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Permit all users to access TV tuner
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2040", MODE="0666"
    SUBSYSTEM=="video4linux", ATTRS{idVendor}=="2040", MODE="0666"
    SUBSYSTEM=="dvb", ATTRS{idVendor}=="2040", MODE="0666"
  '';

  # Enable smartd to monitor the spinning disk.
  services.smartd = {
    enable = true;
    devices = [
      {
        device = "/dev/disk/by-id/ata-ST5000LM000-2U8170_WCJ6ZE69";
      }
    ];
  };

  services.deluge = {
    enable = true;
    web.enable = true;
    group = "media";
  };

  # creating network namespace
  systemd.services."netns@" = {
    description = "%I network namespace";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
      ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
    };
  };

  # set proper DNS for VPN
  # environment.etc."netns/wg/resolv.conf".text = "nameserver 10.2.0.1";

  # setting up wireguard interface within network namespace
  systemd.services.wg = {
    description = "wg network interface";
    bindsTo = [ "netns@wg.service" ];
    requires = [ "network-online.target" ];
    after = [ "netns@wg.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = with pkgs; writers.writeBash "wg-up" ''
        set -e
        ${iproute2}/bin/ip link add wg0 type wireguard
        ${iproute2}/bin/ip link set wg0 netns wg
        ${iproute2}/bin/ip -n wg address add 10.2.0.2/32 dev wg0
        ${iproute2}/bin/ip netns exec wg \
          ${wireguard-tools}/bin/wg setconf wg0 /etc/nixos/wireguard/wg0.conf
        ${iproute2}/bin/ip -n wg link set wg0 up
        # need to set lo up as network namespace is started with lo down
        ${iproute2}/bin/ip -n wg link set lo up
        ${iproute2}/bin/ip -n wg route add default dev wg0
      '';
      ExecStop = with pkgs; writers.writeBash "wg-down" ''
        ${iproute2}/bin/ip -n wg route del default dev wg0
        ${iproute2}/bin/ip -n wg link del wg0
      '';
    };
  };

  # binding deluged to network namespace
  systemd.services.deluged.bindsTo = [ "netns@wg.service" ];
  systemd.services.deluged.requires = [ "network-online.target" "wg.service" ];
  systemd.services.deluged.serviceConfig.NetworkNamespacePath = [ "/var/run/netns/wg" ];

  # allowing delugeweb to access deluged in network namespace, a socket is necesarry
  systemd.sockets."proxy-to-deluged" = {
   enable = true;
   description = "Socket for Proxy to Deluge Daemon";
   listenStreams = [ "58846" ];
   wantedBy = [ "sockets.target" ];
  };

  # creating proxy service on socket, which forwards the same port from the root namespace to the isolated namespace
  systemd.services."proxy-to-deluged" = {
   enable = true;
   description = "Proxy to Deluge Daemon in Network Namespace";
   requires = [ "deluged.service" "proxy-to-deluged.socket" ];
   after = [ "deluged.service" "proxy-to-deluged.socket" ];
   unitConfig = { JoinsNamespaceOf = "deluged.service"; };
   serviceConfig = {
     User = "deluge";
     Group = "media";
     ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:58846";
     PrivateNetwork = "yes";
   };
  };

  services.plex = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.overseerr = {
    enable = true;
    openFirewall = true;
  };

  services.tautulli = {
    enable = true;
    openFirewall = true;
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.bazarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # Enable flakes support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11"; # Did you read the comment?
}
