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

      # Dummy output to force evaluation and print the trace
      packages.aarch64-darwin._glean_trace = (import nixpkgs {
        system = "aarch64-darwin";
        overlays = [ overlay ];
      }).haskell.packages.ghc9103._trace;
    };
}

