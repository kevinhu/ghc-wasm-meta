{ autoPatchelfHook, stdenvNoCC, }:
let
  common-src = builtins.fromJSON (builtins.readFile ../autogen.json);
  wasi-sdk-src = builtins.fetchTarball common-src.wasi-sdk;
  libffi-wasm-src = builtins.fetchTarball common-src.libffi-wasm;
in
stdenvNoCC.mkDerivation {
  name = "wasi-sdk";
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    cp -a ${wasi-sdk-src} $out
    chmod -R u+w $out

    patchShebangs $out
    autoPatchelf $out/bin

    cp -a ${libffi-wasm-src}/libffi-wasm/include/. $out/share/wasi-sysroot/include
    cp -a ${libffi-wasm-src}/libffi-wasm/lib/. $out/share/wasi-sysroot/lib/wasm32-wasi
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    pushd "$(mktemp -d)"
    echo '#include <stdio.h>' >> test.c
    echo 'int main(void) { printf("test"); }' >> test.c
    $out/bin/clang test.c -lffi -o test.wasm
    popd
  '';
  dontFixup = true;
  strictDeps = true;
}
