{
  description = "My take on this NixOS thing";

  inputs = {
    # Core NixOS package repository (bleeding edge)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Stable NixOS packages for compatibility
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # User environment and dotfile management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system configuration management
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak application management
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=v0.6.0";

    # KDE Plasma desktop configuration management
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Hardware-specific optimizations and drivers
    hardware.url = "github:nixos/nixos-hardware";

    # Declarative disk partitioning for automated deployment
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin color scheme for consistent theming
    catppuccin.url = "github:catppuccin/nix";

    # Secrets management with age encryption
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Curated wallpaper collection
    walls = {
      url = "github:dharmx/walls";
      flake = false;
    };

    # Dynamic monitor configuration for Hyprland
    hyprdynamicmonitors = {
      url = "github:fiffeek/hyprdynamicmonitors";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wayland wallpaper daemon (swww replacement)
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia desktop shell (bar, notifications, lock screen)
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Spicetify configuration (Spotify theming)
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen browser - Firefox-based privacy browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    awww,
    catppuccin,
    disko,
    home-manager,
    hyprdynamicmonitors,
    nix-darwin,
    nixpkgs,
    noctalia,
    sops-nix,
    walls,
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
          overlays = builtins.attrValues outputs.overlays;
        };
        extraSpecialArgs = {
          inherit inputs outputs;
          userConfig = users.${username};
          nhModules = "${self}/modules/home-manager";
        };
        modules = [
          ./home/${username}/${hostname}
          catppuccin.homeModules.catppuccin
          hyprdynamicmonitors.homeManagerModules.default
          noctalia.homeModules.default
          inputs.spicetify-nix.homeManagerModules.default
        ];
      };

    # Function for Darwin system configuration
    mkDarwinConfiguration = system: hostname: username:
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs outputs hostname;
          userConfig = users.${username};
          darwinModules = "${self}/modules/darwin";
        };
        modules = [./hosts/${hostname}];
      };
  in {
    nixosConfigurations = {
      weepinbell = mkNixosConfiguration "weepinbell" "daniel";
      kamino = mkNixosConfiguration "kamino" "daniel";
      tatooine = mkNixosConfiguration "tatooine" "daniel";
    };

    darwinConfigurations = {
      coruscant = mkDarwinConfiguration "x86_64-darwin" "coruscant" "daniel";
    };

    homeConfigurations = {
      "daniel@weepinbell" = mkHomeConfiguration "x86_64-linux" "daniel" "weepinbell";
      "daniel@coruscant" = mkHomeConfiguration "x86_64-darwin" "daniel" "coruscant";
    };

    overlays = import ./overlays {inherit inputs;};
  };
}
