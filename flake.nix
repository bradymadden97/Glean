{
  description = "Glean custom overlay flake for aarch64-darwin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      overlay =
        final: prev:
        let
          hlib = final.haskell.lib;
          overlayHS = hfinal: hprev: {
            glean =
              (hlib.overrideCabal (old: {
                libraryHaskellDepends = old.libraryHaskellDepends ++ [ hfinal.hinotify ];
                jailbreak = true;
              }) hprev.glean).overrideAttrs
                (oldAttrs: {
                  postPatch = ''
                    ${oldAttrs.postPatch or ""}
                    rm Setup.hs
                  '';
                });
            fb-util =
              (hlib.dontCheck (hlib.unmarkBroken (hlib.doJailbreak hprev.fb-util))).overrideAttrs
                (oldAttrs: {
                  env = (prev.env or { }) // {
                    NIX_CFLAGS_COMPILE = "${
                      oldAttrs.env.NIX_CFLAGS_COMPILE or ""
                    } -DGFLAGS_IS_A_DLL=0 -DGLOG_USE_GLOG_EXPORT -DGLOG_USE_GFLAGS -lglog";
                  };
                  postPatch = ''
                    ${oldAttrs.postPatch or ""}
                    substituteInPlace ./fb-util.cabal --replace-fail "libglog," "" --replace-fail "g++" "c++"
                    substituteInPlace ./Util/AsanAlloc.cpp --replace-fail "#include <malloc.h>" "#include <stdlib.h>"
                  '';
                });
            thrift-compiler = hlib.doJailbreak hprev.thrift-compiler;
            thrift-lib = hlib.dontCheck (hlib.doJailbreak hprev.thrift-lib);
            thrift-http = hlib.dontCheck (hlib.doJailbreak hprev.thrift-http);
            thrift-haxl = hlib.dontCheck (hlib.doJailbreak hprev.thrift-haxl);
            fb-stubs = hlib.unmarkBroken (hlib.doJailbreak hprev.fb-stubs);
            folly-clib = hprev.callCabal2nixWithOptions "folly-clib" (final.fetchzip {
              url = "mirror://hackage/folly-clib-20250713.1537/folly-clib-20250713.1537.tar.gz";
              sha256 = "sha256-pmiJ9TDn/TGs/DZwdkk0hl9rCyBjIeQfNDg6mTEMH40=";
            }) "-f-bundled-folly" { libfolly = final.folly; };
            haxl = (hlib.unmarkBroken hprev.haxl).overrideAttrs (oldAttrs: {
              postPatch = "rm Setup.hs";
            });
            haskell-names = hlib.unmarkBroken (hlib.dontCheck (hlib.doJailbreak hprev.haskell-names));
            mangle = hlib.doJailbreak hprev.mangle;
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

      # Expose the package set for aarch64-darwin only
      packages.aarch64-darwin.hsPkgs = import nixpkgs {
        system = "aarch64-darwin";
        overlays = [ overlay ];
      };
    };
}

