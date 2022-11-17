{
  description = "Personal dotfiles";

  nixConfig = {
    extra-experimental-features = "nix-command flakes ca-derivations";
    extra-substituters =
      "https://cache.nixos.org https://nix-community.cachix.org";
    extra-trusted-public-keys =
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
  };

  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    flake-utils.url = "github:numtide/flake-utils";

    nix-index-database.url = "github:houstdav000/nix-index-database-stable";

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixos";
    };

    sops-nix-unstable = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixos";
      inputs.utils.follows = "flake-utils";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, ... }@inputs:
    with inputs;
    {
      lib = import ./lib;

      homeConfigurations = {
        dh-framework = self.lib.hmConfig {
          inherit inputs;

          username = "david";
          modules = [ ./homeConfigurations/dh-framework.nix ];
        };

        pbp = self.lib.hmConfig {
          inherit inputs;

          username = "david";
          system = "aarch64-linux";
          modules = [ ./homeConfigurations/pbp.nix ];
        };

        wsl = self.lib.hmConfig {
          inherit inputs;

          username = "david";
          modules = [ ./homeConfigurations/wsl.nix ];
        };
      };

      homeModules = import ./homeModules;

      nixosConfigurations = {
        min = self.lib.defFlakeSystem {
          inherit self;

          modules = [ ./nixos/hosts/min/configuration.nix ];
        };

        dh-framework = self.lib.defFlakeSystem {
          inherit self;

          cpuVendor = "intel";
          workstation = true;

          modules = [
            nixos-hardware.nixosModules.framework
            sops-nix.nixosModules.sops
            impermanence.nixosModules.impermanence
            ./nixos/hosts/dh-framework/configuration.nix
          ];
        };

        ashley = self.lib.defFlakeSystem {
          inherit self;

          modules = [ ./nixos/hosts/ashley/configuration.nix ];
        };
      };

      checks.x86_64-linux = (nixpkgs.lib.genAttrs (builtins.attrNames self.nixosConfigurations) (name: self.nixosConfigurations."${name}".config.system.build.toplevel)) //
      (import ./tests {
        inherit home-manager;

        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      });

    } // flake-utils.lib.eachDefaultSystem (system: {
      checks.pre-commit-check = pre-commit-hooks.lib."${system}".run {
        src = ./.;
        hooks = {
          deadnix.enable = true;
          nixpkgs-fmt.enable = true;
          statix.enable = true;
        };
      };
      devShells = {
        default =
          let
            pkgs = import nixpkgs-unstable {
              inherit system;
              overlays = [ sops-nix-unstable.overlay ];
            };
          in
          pkgs.mkShell {
            inherit (self.checks."${system}".pre-commit-check) shellHook;

            nativeBuildInputs = with pkgs; [
              # pre-commit
              pre-commit

              # Nix formatter
              alejandra
              nixfmt
              nixpkgs-fmt

              # Nix linting
              deadnix
              nix-linter
              statix

              # sops-nix
              sops
              sops-init-gpg-key
              sops-import-keys-hook
            ];

            sopsPGPKeyDirs = [
              ./keys/hosts
              ./keys/users
            ];
          };
        no-env =
          let
            pkgs = import nixpkgs-unstable {
              inherit system;
              overlays = [ sops-nix-unstable.overlay ];
            };
          in
          pkgs.mkShell {
            packages = with pkgs; [
              git
              gnupg
              pinentry-qt
              neovim

              # pre-commit
              pre-commit

              # Nix formatter
              alejandra
              nixfmt
              nixpkgs-fmt

              # Nix linting
              deadnix
              nix-linter
              statix

              # sops-nix
              sops
              sops-init-gpg-key
              sops-import-keys-hook
            ];

            sopsPGPKeyDirs = [
              ./keys/hosts
              ./keys/users
            ];

            shellHook = ''
              ${self.checks."${system}".pre-commit-check.shellHook}

              alias g="git"
              alias ga="git add"
              alias gaa="git add --all"
              alias gc="git commit"
              alias gcmsg="git commit -m"
              alias gd="git diff"
              alias gl="git pull"
              alias gp="git push"
              alias gsb="git status -sb"
              alias n="nix"
              alias nfu="nix flake update"
              alias nosswf="nixos-rebuild switch --use-remote-sudo --flake ."
              alias v="nvim"
            '';
          };
      };
    });
}
