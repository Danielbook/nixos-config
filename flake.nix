{
  description = "My take on this NixOS thing";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative flatpak manager
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=v0.6.0";

    # Declarative kde plasma manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # NixOS profiles to optimize settings for different hardware
    hardware.url = "github:nixos/nixos-hardware";

    # Global catppuccin theme
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = {
    self,
    catppuccin,
    home-manager,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};

    # Define user configurations
    users = {
      daniel = {
        avatar = ./files/avatar/face;
        email = "daniel@bookorjeman.se";
        fullName = "Daniel Book";
        name = "daniel";
      };
    };

    # Function for NixOS system configuration
    mkNixosConfiguration = hostname: username:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs hostname;
          userConfig = users.${username};
          nixosModules = "${self}/modules/nixos";
        };
        modules = [./hosts/${hostname}];
      };

    # Function for Home Manager configuration
    mkHomeConfiguration = system: username: hostname:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
        };
        extraSpecialArgs = {
          inherit inputs outputs;
          userConfig = users.${username};
          nhModules = "${self}/modules/home-manager";
        };
        modules = [
          ./home/${username}/${hostname}
          catppuccin.homeModules.catppuccin
        ];
      };
  in {
    nixosConfigurations = {
      weepinbell = mkNixosConfiguration "weepinbell" "daniel";
    };

    homeConfigurations = {
      "daniel@weepinbell" = mkHomeConfiguration "x86_64-linux" "daniel" "weepinbell";
    };

    overlays = import ./overlays {inherit inputs;};

    devShells = {
      ${system} = {
        web = import ./shells/web.nix {inherit pkgs;};

        # Optional default fallback:
        default = import ./shells/web.nix {inherit pkgs;};
      };
    };
  };
}
