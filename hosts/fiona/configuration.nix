# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "fiona";

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

  hardware.bluetooth.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    ragenix
  #  wget
  ];

  # Caddy reverse proxy (with ACME DNS integration with Cloudflare)
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-i7OoxiHJ4Stfp7SnxOryLAXS6w5+PJCnEydOakhFYcE=";
    };
    virtualHosts."ha.nasmith.me".extraConfig = ''
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }
      reverse_proxy localhost:8123 {
        header_down X-Real-IP {http.request.remote}
        header_down X-Forwarded-For {http.request.remote}
        websocket
        transparent
      }
    '';
  };
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.age.secrets.cloudflare.path;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.wyoming = {
    faster-whisper.servers.ha = {
      enable = true;
      device = "cpu";
      model = "tiny-int8";
      uri = "tcp://localhost:10300";
      language = "en";
    };
    piper.servers.ha = {
      enable = true;
      voice = "en_GB-semaine-medium";
      speaker = 0;
      uri = "tcp://localhost:10200";
      streaming = true;
    };
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
    };
    oci-containers = {
      backend = "podman";
      containers = {
        homeassistant = {
          volumes = [
            "/var/lib/homeassistant:/config"
            "/run/dbus:/run/dbus:ro"
          ];
          environment.TZ = "America/Chicago";
          # Note: The image will not be updated on rebuilds, unless the version label changes
          image = "ghcr.io/home-assistant/home-assistant:2026.4.1";
          extraOptions = [ 
            # Use the host network namespace for all sockets
            "--network=host"
            # Permit bluetooth
            "--cap-add=NET_ADMIN"
            "--cap-add=NET_RAW"
            # Pass devices into the container, so Home Assistant can discover and make use of them
            # "--device=/dev/ttyACM0:/dev/ttyACM0"
          ];
        };
      };
    };
  };

  users.users.nsmith = {
    extraGroups = [
      "podman"
    ];
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # Enable flakes support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11"; # Did you read the comment?
}
