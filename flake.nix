{
  inputs = {
    haskell-nix = {
      type = "github";
      owner = "input-output-hk";
      repo = "haskell.nix";
    };
  };

  outputs = { self, haskell-nix, }:
    haskell-nix.inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import haskell-nix.inputs.nixpkgs-unstable {
          inherit system;
          config = haskell-nix.config;
          overlays = [ haskell-nix.overlay ];
        };
        default = pkgs.symlinkJoin {
          name = "ghc-wasm";
          paths = [
            pkgs.haskellPackages.alex
            pkgs.haskellPackages.happy
            wasm32-wasi-ghc-gmp
            wasi-sdk
            deno
            binaryen
            wabt
            wasmtime
            wasmedge
            toywasm
            wasm3
            wasmer
            wizer
            cabal
            wasm32-wasi-cabal
            proot
            wasm-run
          ];
        };
        wasm32-wasi-ghc-gmp =
          pkgs.callPackage ./pkgs/wasm32-wasi-ghc.nix { flavour = "gmp"; };
        wasm32-wasi-ghc-native =
          pkgs.callPackage ./pkgs/wasm32-wasi-ghc.nix { flavour = "native"; };
        wasm32-wasi-ghc-unreg =
          pkgs.callPackage ./pkgs/wasm32-wasi-ghc.nix { flavour = "unreg"; };
        wasi-sdk = pkgs.callPackage ./pkgs/wasi-sdk.nix { };
        deno = pkgs.callPackage ./pkgs/deno.nix { };
        binaryen = pkgs.callPackage ./pkgs/binaryen.nix { };
        wabt = pkgs.callPackage ./pkgs/wabt.nix { };
        wasmtime = pkgs.callPackage ./pkgs/wasmtime.nix { };
        wasmedge = pkgs.callPackage ./pkgs/wasmedge.nix { };
        toywasm = pkgs.callPackage ./pkgs/toywasm.nix { };
        wasm3 = pkgs.callPackage ./pkgs/wasm3.nix { };
        wasmer = pkgs.callPackage ./pkgs/wasmer.nix { };
        wizer = pkgs.callPackage ./pkgs/wizer.nix { };
        cabal = pkgs.callPackage ./pkgs/cabal.nix { };
        wasm32-wasi-cabal =
          pkgs.callPackage ./pkgs/wasm32-wasi-cabal.nix { flavour = "gmp"; };
        proot = pkgs.callPackage ./pkgs/proot.nix { };
        wasm-run = pkgs.callPackage ./pkgs/wasm-run.nix { };
      in
      {
        packages = {
          inherit default wasm32-wasi-ghc-gmp wasm32-wasi-ghc-native
            wasm32-wasi-ghc-unreg wasi-sdk deno binaryen wabt wasmtime wasmedge
            wasmer wizer cabal wasm32-wasi-cabal proot wasm-run;
        };
      });
}
