{ autoPatchelfHook
, hostPlatform
, lib
, runtimeShellPackage
, stdenv
, stdenvNoCC
, writeText
,
}:
let
  wasmtime-key =
    if hostPlatform.isDarwin then
      if hostPlatform.isAarch64 then
        "wasmtime_aarch64_darwin"
      else
        "wasmtime_x86_64_darwin"
    else if hostPlatform.isAarch64 then
      "wasmtime_aarch64_linux"
    else
      "wasmtime";
  src = builtins.fetchTarball
    ((builtins.fromJSON (builtins.readFile ../autogen.json))."${wasmtime-key}");
in
stdenvNoCC.mkDerivation {
  name = "wasmtime";

  dontUnpack = true;

  buildInputs = [ runtimeShellPackage ]
    ++ lib.optionals hostPlatform.isLinux [ stdenv.cc.cc.lib ];
  nativeBuildInputs = lib.optionals hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ${src}/wasmtime $out/bin/wasmtime
    install -Dm755 ${../wasm-run/wasmtime.sh} $out/bin/wasmtime.sh
    patchShebangs $out
    substituteInPlace $out/bin/wasmtime.sh \
      --replace wasmtime "$out/bin/wasmtime"
  '';

  setupHook = writeText "wasmtime-setup-hook" ''
    addWasmtimeHook() {
      export CROSS_EMULATOR=@out@/bin/wasmtime.sh
    }

    addEnvHooks "$hostOffset" addWasmtimeHook
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wasmtime --version
  '';

  strictDeps = true;
}
