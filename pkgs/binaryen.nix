{ fetchurl, stdenvNoCC, unzip }:
let
  src = fetchurl
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).binaryen);
in
stdenvNoCC.mkDerivation {
  name = "binaryen";
  inherit src;
  nativeBuildInputs = [ unzip ];
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ./* $out/bin
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    MIMALLOC_VERBOSE=1 $out/bin/wasm-opt --version
  '';
  allowedReferences = [ ];
}
