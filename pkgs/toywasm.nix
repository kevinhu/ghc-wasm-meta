{ autoPatchelfHook, stdenvNoCC, }:
let
  src = builtins.fetchurl
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).toywasm);
in
stdenvNoCC.mkDerivation {
  name = "toywasm";
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir $out
    tar xzf ${src} -C $out
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/toywasm --version
  '';
  strictDeps = true;
}
