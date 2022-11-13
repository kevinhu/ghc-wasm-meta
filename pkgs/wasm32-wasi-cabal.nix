{ bignumBackend, callPackage, writeShellScriptBin, }:
let
  cabal = callPackage ./cabal.nix { };
  wasm32-wasi-ghc =
    callPackage ./wasm32-wasi-ghc.nix { inherit bignumBackend; };
in
writeShellScriptBin "wasm32-wasi-cabal" ''
  export CABAL_DIR="''${CABAL_DIR:-$HOME/.ghc-wasm/.cabal}"

  if [ ! -f "$CABAL_DIR/config" ]
  then
    mkdir -p "$CABAL_DIR"
    cp ${../cabal.config} "$CABAL_DIR/config"
    chmod u+w "$CABAL_DIR/config"
  fi

  exec ${cabal}/bin/cabal \
    --with-compiler=${wasm32-wasi-ghc}/bin/wasm32-wasi-ghc \
    --with-hc-pkg=${wasm32-wasi-ghc}/bin/wasm32-wasi-ghc-pkg \
    --with-hsc2hs=${wasm32-wasi-ghc}/bin/wasm32-wasi-hsc2hs \
    ''${1+"$@"}
''
