{
  description = "Minimal Glean flake for aarch64-darwin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.glean = pkgs.haskell.packages.ghc9103.callCabal2nix "glean" ./. ./. {
        preConfigure = ''
          if [ ! -e glean.cabal ]; then
            if [ -e glean.cabal.in ]; then
              cp glean.cabal.in glean.cabal
            fi
          fi
        '';
      };
    };
}
