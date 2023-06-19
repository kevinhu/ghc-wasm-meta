{ autoPatchelfHook, fetchurl, stdenv, stdenvNoCC, unzip, }:
let
  src = fetchurl
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).wizer);
in
stdenvNoCC.mkDerivation {
  name = "wizer";
  inherit src;
  sourceRoot = ".";
  buildInputs = [ stdenv.cc.cc.lib ];
  nativeBuildInputs = [ autoPatchelfHook unzip ];
  installPhase = ''
    mkdir -p $out/bin
    tar -xJf wizer-* -C $out/bin --strip-components=1 --wildcards '*/wizer'
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wizer --version
  '';
  strictDeps = true;
}
