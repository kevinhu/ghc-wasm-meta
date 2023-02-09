{ stdenvNoCC }:
let
  src = builtins.fetchTarball
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).wasm3);
in
stdenvNoCC.mkDerivation {
  name = "wasm3";
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ${src} $out/bin/wasm3
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wasm3 --version
  '';
  allowedReferences = [ ];
}
