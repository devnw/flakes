{
  description = "Development flake with stable and unstable packages";
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs-stable, nixpkgs-unstable, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs-stable = import nixpkgs-stable {
          system = system;
          config.allowUnfree = true;
        };
        pkgs-unstable = import nixpkgs-unstable {
          system = system;
          config.allowUnfree = true;
        };

        pkgs = pkgs-stable.extend (final: prev: {
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
        });

        commonPackages = with pkgs; [
          # System tools
          nixfmt-rfc-style
          inetutils
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
        packages = {
          inherit pkgs;
          allPackages = pkgs;
          commonPackages = commonPackages;
          goPackages = goPackages;
          ansiblePackages = ansiblePackages;
        };
        overlays = {
          default = final: prev: {
            # Expose your overlay if needed
            # For example, you can merge pkgs into prev
          };
        };
        # Expose devShells if needed
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
