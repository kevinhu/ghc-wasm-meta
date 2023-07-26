{ stdenvNoCC }:
let
  src = builtins.fetchTarball
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).binaryen);
in
stdenvNoCC.mkDerivation {
  name = "binaryen";
  inherit src;
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ${src}/bin/* $out/bin
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    MIMALLOC_VERBOSE=1 $out/bin/wasm-opt --version
  '';
  allowedReferences = [ ];
}
