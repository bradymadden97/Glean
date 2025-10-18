{
  description = "Glean debug overlay flake for aarch64-darwin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      overlay =
        final: prev:
        let
          hlib = final.haskell.lib;
          overlayHS = hfinal: hprev: {
            _trace = builtins.trace (builtins.typeOf hprev.glean) null;
          };
        in
        {
          haskell = prev.haskell // {
            packages = prev.haskell.packages // {
              ghc9103 = prev.haskell.packages.ghc9103.override (old: {
                overrides = prev.lib.fold prev.lib.composeExtensions (old.overrides or (_: _: { })) [ overlayHS ];
              });
            };
          };
        };
    in
    {
      overlays.default = overlay;
      # No packages output needed for this test
    };
}

