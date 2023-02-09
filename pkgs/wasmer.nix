{ stdenvNoCC }:
let
  src = builtins.fetchurl
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).wasmer);
in
stdenvNoCC.mkDerivation {
  name = "wasmer";
  dontUnpack = true;
  installPhase = ''
    mkdir $out
    tar xzf ${src} -C $out
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wasmer --version
  '';
  allowedReferences = [ ];
}
