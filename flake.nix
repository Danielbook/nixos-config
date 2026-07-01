{
  description = "My take on this Nix thing";

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

    # Declarative disk partitioning (k3s node installs via nixos-anywhere)
    disko = {
      url = "github:nix-community/disko";
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

    # macOS system management
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      catppuccin,
      home-manager,
      hyprdynamicmonitors,
      nix-darwin,
      nixpkgs,
      noctalia,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Define user configurations
      users = {
        daniel = {
          avatar = ./files/avatar/face;
          email = "daniel@bookorjeman.se";
          fullName = "Daniel Böök";
          name = "daniel";
        };
      };

      # Function for NixOS system configuration
      mkNixosConfiguration =
        hostname: username:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs hostname;
            userConfig = users.${username};
            nixosModules = "${self}/modules/nixos";
          };
          modules = [ ./hosts/${hostname} ];
        };

      # Function for nix-darwin system configuration
      mkDarwinConfiguration =
        hostname: username:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs outputs hostname;
            userConfig = users.${username};
            darwinModules = "${self}/modules/nix-darwin";
          };
          modules = [ ./hosts/${hostname} ];
        };

      # Function for Home Manager configuration
      mkHomeConfiguration =
        system: username: hostname:
        {
          extraModules ? [ ],
        }:
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
          ]
          ++ extraModules;
        };

    in
    {
      nixosConfigurations = {
        coruscant = mkNixosConfiguration "coruscant" "daniel";

        # k3s cluster — see docs/cluster-implementation.md.
        # naboo (M80q): bootstrap control-plane. endor/jupiter/tatooine follow.
        naboo = mkNixosConfiguration "naboo" "daniel";

        # endor (M70q): 2nd control-plane, joins naboo's etcd via the API VIP.
        endor = mkNixosConfiguration "endor" "daniel";
      };

      darwinConfigurations = {
        dagobah = mkDarwinConfiguration "dagobah" "daniel";
      };

      homeConfigurations = {
        "daniel@coruscant" = mkHomeConfiguration "x86_64-linux" "daniel" "coruscant" {
          extraModules = [
            catppuccin.homeModules.catppuccin
            hyprdynamicmonitors.homeManagerModules.default
            noctalia.homeModules.default
            inputs.spicetify-nix.homeManagerModules.default
          ];
        };

        "daniel@dagobah" = mkHomeConfiguration "aarch64-darwin" "daniel" "dagobah" {
          extraModules = [
            catppuccin.homeModules.catppuccin
          ];
        };

        # Headless k3s node — CLI tooling only. catppuccin is required by the
        # shared home `common` layer (tmux/starship/etc. theming).
        "daniel@naboo" = mkHomeConfiguration "x86_64-linux" "daniel" "naboo" {
          extraModules = [
            catppuccin.homeModules.catppuccin
          ];
        };

        "daniel@endor" = mkHomeConfiguration "x86_64-linux" "daniel" "endor" {
          extraModules = [
            catppuccin.homeModules.catppuccin
          ];
        };
      };

      overlays = import ./overlays { };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            nixfmt
            deadnix
            statix
            just
            sops
          ];
        };
      });
    };
}
