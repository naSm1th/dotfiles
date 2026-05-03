{
  description = "System state configured by Nix flakes";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.11";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    agenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, nixpkgs-unstable, agenix, ... } @ inputs:
  let
    shared = [
      ./modules/users/nsmith.nix
      ./modules/network
      ./modules/agenix
#      ./modules/homer
      agenix.nixosModules.default
    ];
    media = [
#      ./modules/vpn
      ./modules/plex
#      ./modules/prowlarr
#      ./modules/overseerr
#      ./modules/radarr
#      ./modules/lidarr
#      ./modules/barzarr
#      ./modules/deluge
#      ./modules/sabnzbd
    ];
  in
  {
    nixosConfigurations = {
      donkey = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = shared ++ [
          ./hosts/donkey/configuration.nix
        ];
      };

      farquaad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = shared ++ [
          ./hosts/farquaad/configuration.nix
        ];
      };

      fiona = nixpkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        modules = shared ++ [
          ./hosts/fiona/configuration.nix
        ];
      };

      magicmirror = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = shared ++ [
          ./hosts/magicmirror/configuration.nix
        ];
      };

      pussinboots = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = shared ++ [
          ./hosts/pussinboots/configuration.nix
        ];
      };

      shrek = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = shared ++ [
          ./hosts/shrek/configuration.nix
        ];
      };

      laptoppy = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = shared ++ [
          ./hosts/laptoppy/configuration.nix
        ];
      };
    };
  };
}
