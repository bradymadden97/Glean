# flake.nix
{
  description = "Example flake with a test binary for M1 Mac";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: {
    packages.aarch64-darwin.test = nixpkgs.legacyPackages.aarch64-darwin.stdenv.mkDerivation {
      pname = "test";
      version = "0.1.0";
      src = ./.;
      buildPhase = ''
        mkdir -p $out/bin
        echo '#!/bin/sh' > $out/bin/test
        echo 'echo Hello, world!' >> $out/bin/test
        chmod +x $out/bin/test
      '';
      installPhase = "";
    };
  };
}

