{
  description = "Flake that builds a test binary for M1 Macs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: {
    packages.aarch64-darwin.test = nixpkgs.legacyPackages.aarch64-darwin.stdenv.mkDerivation {
      pname = "test";
      version = "0.1.0";
      src = ./.;
      buildPhase = ''
        echo '#!/bin/sh' > test
        echo 'echo Hello, world!' >> test
        chmod +x test
      '';
      installPhase = ''
        mkdir -p $out/bin
        mv test $out/bin/test
      '';
      dontPatchShebangs = true;
    };
  };
}

