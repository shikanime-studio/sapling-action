{
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
      devenv.shells.default = {
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
        packages = [
          pkgs.gh
        ];
      };
    };
}
