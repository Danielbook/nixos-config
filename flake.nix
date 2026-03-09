{
  description = "My take on this NixOS thing";

  inputs = {
    # Core NixOS package repository (bleeding edge)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # User environment and dotfile management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak application management
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=v0.6.0";

    # Catppuccin color scheme for consistent theming
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      inputs.home-manager.follows = "home-manager";
    };

    # Git worktree management CLI for parallel AI agent workflows
    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    catppuccin,
    home-manager,
    hyprdynamicmonitors,
    nixpkgs,
    noctalia,
    ...
  } @ inputs: let
    inherit (self) outputs;

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
          config.allowUnfree = true;
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

  in {
    nixosConfigurations = {
      weepinbell = mkNixosConfiguration "weepinbell" "daniel";
    };

    homeConfigurations = {
      "daniel@weepinbell" = mkHomeConfiguration "x86_64-linux" "daniel" "weepinbell";
    };

    overlays = import ./overlays {};

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;

    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      packages = with nixpkgs.legacyPackages.x86_64-linux; [
        nixfmt
        deadnix
        statix
        just
        sops
      ];
    };
  };
}
