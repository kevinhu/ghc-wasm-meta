{ stdenvNoCC }:
let
  src = builtins.fetchurl
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).wasmtime);
in
stdenvNoCC.mkDerivation {
  name = "wasmtime";
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ${src} $out/bin/wasmtime
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wasmtime --version
  '';
  allowedReferences = [ ];
}
