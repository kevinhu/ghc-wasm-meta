{ autoPatchelfHook, bignumBackend, callPackage, gmp, stdenvNoCC, }:
let
  common-src = builtins.fromJSON (builtins.readFile ../autogen.json);
  src = builtins.fetchTarball common-src."wasm32-wasi-ghc-${bignumBackend}";
  wasi-sdk = callPackage ./wasi-sdk.nix { };
in
stdenvNoCC.mkDerivation {
  name = "wasm32-wasi-ghc-${bignumBackend}";

  buildInputs = [ gmp ];
  nativeBuildInputs = [ autoPatchelfHook ];

  inherit src;

  preConfigure = ''
    patchShebangs .
    autoPatchelf .

    configureFlagsArray+=(
      AR=${wasi-sdk}/bin/llvm-ar
      CC=${wasi-sdk}/bin/clang
      CXX=${wasi-sdk}/bin/clang++
      LD=${wasi-sdk}/bin/wasm-ld
      NM=${wasi-sdk}/bin/llvm-nm
      OBJCOPY=${wasi-sdk}/bin/llvm-objcopy
      OBJDUMP=${wasi-sdk}/bin/llvm-objdump
      RANLIB=${wasi-sdk}/bin/llvm-ranlib
      SIZE=${wasi-sdk}/bin/llvm-size
      STRINGS=${wasi-sdk}/bin/llvm-strings
      STRIP=${wasi-sdk}/bin/llvm-strip
      CONF_CC_OPTS_STAGE2="-Wno-int-conversion -Wno-strict-prototypes -Oz -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mreference-types"
      CONF_CXX_OPTS_STAGE2="-Wno-int-conversion -Wno-strict-prototypes -fno-exceptions -Oz -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mreference-types"
      CONF_GCC_LINKER_OPTS_STAGE2="-Wl,--compress-relocations,--error-limit=0,--growable-table,--stack-first,--strip-debug -Wno-unused-command-line-argument"
      --host=x86_64-linux
      --target=wasm32-wasi
      --with-intree-gmp
      --with-system-libffi
    )
  '';

  dontBuild = true;

  doInstallCheck = true;
  installCheckPhase = ''
    pushd "$(mktemp -d)"
    echo 'import GHC' >> test.hs
    echo 'main = runGhc Nothing $ pure ()' >> test.hs
    $out/bin/wasm32-wasi-ghc -package ghc test.hs -o test.wasm
    popd
  '';

  dontFixup = true;
  strictDeps = true;
}
