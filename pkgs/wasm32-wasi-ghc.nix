{ callPackage, flavour, runtimeShellPackage, stdenvNoCC, }:
let
  common-src = builtins.fromJSON (builtins.readFile ../autogen.json);
  src = builtins.fetchTarball common-src."wasm32-wasi-ghc-${flavour}";
  wasi-sdk = callPackage ./wasi-sdk.nix { };
in
stdenvNoCC.mkDerivation {
  name = "wasm32-wasi-ghc-${flavour}";

  inherit src;

  nativeBuildInputs = [ wasi-sdk ];
  buildInputs = [ runtimeShellPackage ];

  preConfigure = ''
    patchShebangs .
    configureFlags="$configureFlags --build=$system --host=$system $CONFIGURE_ARGS"
  '';

  configurePlatforms = [ ];

  dontBuild = true;
  dontFixup = true;
  allowedReferences = [ "out" runtimeShellPackage wasi-sdk ];
}
