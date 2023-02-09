{ autoPatchelfHook, stdenvNoCC }:
let
  src = builtins.fetchTarball
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).iwasm);
in
stdenvNoCC.mkDerivation {
  name = "iwasm";
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ${src} $out/bin/iwasm
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/iwasm --version
  '';
  strictDeps = true;
}
