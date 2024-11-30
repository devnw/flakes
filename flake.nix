{
  description = "Development flake with stable and unstable packages";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # Import stable and unstable package sets
        pkgs-stable = import nixpkgs-stable {
          system = system;
          config.allowUnfree = true;
        };

        pkgs-unstable = import nixpkgs-unstable {
          system = system;
          config.allowUnfree = true;
        };

        # Define the combined package set
        pkgs = pkgs-stable.extend (
          final: prev: {
            # Override specific packages with versions from unstable
            go = pkgs-unstable.go;
            gopls = pkgs-unstable.gopls;
            go-tools = pkgs-unstable.go-tools;
            delve = pkgs-unstable.delve;
            golangci-lint = pkgs-unstable.golangci-lint;
            goreleaser = pkgs-unstable.goreleaser;
            go-licenses = pkgs-unstable.go-licenses;

            python = pkgs-unstable.python3.withPackages (
              subpkgs: with subpkgs; [
                openapi-spec-validator
                detect-secrets
                requests
                python-dotenv
              ]
            );

            # You can add more overrides as needed
          }
        );

        # Define your package groups
        commonPackages = with pkgs; [
          # System tools
          nixfmt-rfc-style
          unixtools.ping
          gnumake
          openssh
          bash
          sudo
          curl
          which
          act
          gcc
          ruby
          git
          sqlite-interactive
          rsync
          # Python
          python3
          _1password-cli
          tailscale
          rsync
          gawk
        ];

        linters = with pkgs; [
          # Lint tools
          gibberish-detector
          addlicense
          shfmt
          pre-commit
          shellcheck
          yamllint
        ];

        goPackages = with pkgs; [
          # Go tools
          go
          gopls
          go-tools
          delve
          golangci-lint
          goreleaser
          go-licenses
        ];

        ansiblePackages = with pkgs; [
          openssh
          # Ansible tools
          ansible
          ansible-lint
          molecule
        ];
      in
      {
        devShells = {
          default = pkgs.mkShell {
            buildInputs = commonPackages ++ linters ++ goPackages ++ ansiblePackages;
          };
          go = pkgs.mkShell { buildInputs = commonPackages ++ linters ++ goPackages; };
          ansible = pkgs.mkShell { buildInputs = commonPackages ++ ansiblePackages; };
        };
      }
    );
}
