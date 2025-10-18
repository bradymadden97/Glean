let
  pkgs = import ./. {
    overlays = [
      overlay
    ];
  };
  inherit (pkgs) lib;
  overlay =
    final: prev:
    let
      overlayHS = hfinal: hprev: {
        glean =
          (hlib.overrideCabal (old: {
            libraryHaskellDepends = old.libraryHaskellDepends ++ [ hfinal.hinotify ];
            jailbreak = true;
          }) hprev.glean).overrideAttrs
            (oldAttrs: {
              # its busted and pointless
              postPatch = ''
                ${oldAttrs.postPatch or ""}
                rm Setup.hs
              '';
            });
        fb-util =
          (hlib.dontCheck (hlib.unmarkBroken (hlib.doJailbreak hprev.fb-util))).overrideAttrs
            (oldAttrs: {
              # why doesn't this work? who knows! it should be doing pkgconfig into the clang command line and it simply does not.
              # env = (oldAttrs.env or {}) // {
              #   NIX_DEBUG = 2;
              # };
              # # jank, should be libraryPkgconfigDepends in overrideCabal but I don't feel like it
              # buildInputs = (oldAttrs.buildInputs or []) ++ [
              #   final.folly
              # ];

              # jank jank jank! works around missing pkg-config in nixpkgs for glog.
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
        # this really shouldn't be this goofy right??
        folly-clib = hprev.callCabal2nixWithOptions "folly-clib" (pkgs.fetchzip {
          url = "mirror://hackage/folly-clib-20250713.1537/folly-clib-20250713.1537.tar.gz";
          sha256 = "sha256-pmiJ9TDn/TGs/DZwdkk0hl9rCyBjIeQfNDg6mTEMH40=";
        }) "-f-bundled-folly" { libfolly = final.folly; };
        haxl = (hlib.unmarkBroken hprev.haxl).overrideAttrs (oldAttrs: {
          # its busted and pointless
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
            overrides = lib.fold lib.composeExtensions (old.overrides or (_: _: { })) [ overlayHS ];
          });
        };
      };
    };
  hlib = pkgs.haskell.lib.compose;
in
{
  hsPkgs = pkgs.haskellPackages;
}
