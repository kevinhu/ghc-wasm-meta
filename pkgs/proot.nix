{ autoPatchelfHook, fetchurl, stdenvNoCC, }:
let
  src = fetchurl
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).proot);
in
stdenvNoCC.mkDerivation {
  name = "proot";
  inherit src;
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 $src $out/bin/proot
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/proot --version
  '';
  strictDeps = true;
}
