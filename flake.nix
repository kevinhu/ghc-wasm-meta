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
        all = pkgs.symlinkJoin {
          name = "ghc-wasm";
          paths = [
            wasm32-wasi-ghc-gmp
            wasi-sdk
            deno
            binaryen
            wabt
            wasmtime
            wasmedge
            wasmer
            wizer
            cabal
            proot
          ];
        };
        wasm32-wasi-ghc-gmp = pkgs.callPackage ./pkgs/wasm32-wasi-ghc.nix {
          bignumBackend = "gmp";
        };
        wasm32-wasi-ghc-native = pkgs.callPackage ./pkgs/wasm32-wasi-ghc.nix {
          bignumBackend = "native";
        };
        wasi-sdk = pkgs.callPackage ./pkgs/wasi-sdk.nix { };
        deno = pkgs.callPackage ./pkgs/deno.nix { };
        binaryen = pkgs.callPackage ./pkgs/binaryen.nix { };
        wabt = pkgs.callPackage ./pkgs/wabt.nix { };
        wasmtime = pkgs.callPackage ./pkgs/wasmtime.nix { };
        wasmedge = pkgs.callPackage ./pkgs/wasmedge.nix { };
        wasmer = pkgs.callPackage ./pkgs/wasmer.nix { };
        wizer = pkgs.callPackage ./pkgs/wizer.nix { };
        cabal = pkgs.callPackage ./pkgs/cabal.nix { };
        proot = pkgs.callPackage ./pkgs/proot.nix { };
      in
      {
        packages = {
          inherit all wasm32-wasi-ghc-gmp wasm32-wasi-ghc-native wasi-sdk deno
            binaryen wabt wasmtime wasmedge wasmer wizer cabal proot;
        };
      });
}
