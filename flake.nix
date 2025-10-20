{
  inputs = {
    devenv.url = "github:cachix/devenv";
    devlib.url = "github:shikanime-studio/devlib";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  nixConfig = {
    extra-public-keys = [
      "shikanime.cachix.org-1:OrpjVTH6RzYf2R97IqcTWdLRejF6+XbpFNNZJxKG8Ts="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
    extra-substituters = [
      "https://shikanime.cachix.org"
      "https://devenv.cachix.org"
    ];
  };

  outputs =
    inputs@{
      devenv,
      devlib,
      flake-parts,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devenv.flakeModule
        treefmt-nix.flakeModule
      ];
      perSystem =
        { pkgs, ... }:
        {
          treefmt = {
            projectRootFile = "flake.nix";
            enableDefaultExcludes = true;
            programs = {
              nixfmt.enable = true;
              prettier.enable = true;
              shfmt.enable = true;
              statix.enable = true;
            };
            settings.global.excludes = [
              ".devenv/*"
              ".direnv/*"
              ".sl/*"
              "LICENSE"
            ];
          };
          devenv = {
            modules = [
              devlib.devenvModule
            ];
            shells.default = {
              containers = pkgs.lib.mkForce { };
              languages.nix.enable = true;
              cachix = {
                enable = true;
                push = "shikanime";
              };
              git-hooks.hooks = {
                actionlint.enable = true;
                deadnix.enable = true;
                flake-checker.enable = true;
              };
              gitignore = {
                enable = true;
                templates = [
                  "repo:github/gitignore/refs/heads/main/Nix.gitignore"
                  "repo:shikanime/gitignore/refs/heads/main/Devenv.gitignore"
                  "tt:jetbrains+all"
                  "tt:linux"
                  "tt:macos"
                  "tt:vim"
                  "tt:visualstudiocode"
                  "tt:windows"
                ];
              };
              packages = [
                pkgs.direnv
                pkgs.gh
                pkgs.sapling
              ];
            };
          };
        };
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };
}
