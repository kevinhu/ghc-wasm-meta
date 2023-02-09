#!/usr/bin/env bash

set -euo pipefail

readonly FLAVOUR="${FLAVOUR:-gmp}"
readonly PREFIX="${PREFIX:-$HOME/.ghc-wasm}"
readonly REPO=$PWD
readonly SKIP_GHC="${SKIP_GHC:-}"

rm -rf "$PREFIX"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

pushd "$workdir"

mkdir -p "$PREFIX/wasi-sdk"
curl -f -L --retry 5 "$(jq -r '."wasi-sdk".url' "$REPO"/autogen.json)" | tar xz -C "$PREFIX/wasi-sdk" --strip-components=1

curl -f -L --retry 5 "$(jq -r '."libffi-wasm".url' "$REPO"/autogen.json)" -o out.zip
unzip out.zip
cp -a out/libffi-wasm/include/. "$PREFIX/wasi-sdk/share/wasi-sysroot/include"
cp -a out/libffi-wasm/lib/. "$PREFIX/wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi"

curl -f -L --retry 5 "$(jq -r .deno.url "$REPO"/autogen.json)" -o deno.zip
unzip deno.zip
mkdir -p "$PREFIX/deno/bin"
install -Dm755 deno "$PREFIX/deno/bin"

mkdir -p "$PREFIX/binaryen"
curl -f -L --retry 5 "$(jq -r .binaryen.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/binaryen" --strip-components=1

mkdir -p "$PREFIX/wabt"
curl -f -L --retry 5 "$(jq -r .wabt.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/wabt" --strip-components=1

mkdir -p "$PREFIX/wasmtime/bin"
curl -f -L --retry 5 "$(jq -r .wasmtime.url "$REPO"/autogen.json)" | tar xJ -C "$PREFIX/wasmtime/bin" --strip-components=1 --wildcards '*/wasmtime'

mkdir -p "$PREFIX/iwasm/bin"
curl -f -L --retry 5 "$(jq -r .iwasm.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/iwasm/bin"

mkdir -p "$PREFIX/wasmedge"
curl -f -L --retry 5 "$(jq -r .wasmedge.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/wasmedge" --strip-components=1

mkdir -p "$PREFIX/toywasm"
curl -f -L --retry 5 "$(jq -r .toywasm.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/toywasm"

curl -f -L --retry 5 "$(jq -r .wasm3.url "$REPO"/autogen.json)" -o wasm3.zip
unzip wasm3.zip
mkdir -p "$PREFIX/wasm3/bin"
cp wasm3 "$PREFIX/wasm3/bin/wasm3"
chmod 755 "$PREFIX/wasm3/bin/wasm3"

mkdir -p "$PREFIX/wasmer"
curl -f -L --retry 5 "$(jq -r .wasmer.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/wasmer"

curl -f -L --retry 5 "$(jq -r .wizer.url "$REPO"/autogen.json)" -o wizer.zip
unzip wizer.zip
mkdir -p "$PREFIX/wizer/bin"
tar xJf wizer-*.tar.xz -C "$PREFIX/wizer/bin" --strip-components=1 --wildcards '*/wizer'

mkdir -p "$PREFIX/proot/bin"
curl -f -L --retry 5 "$(jq -r .proot.url "$REPO"/autogen.json)" -o "$PREFIX/proot/bin/proot"
chmod 755 "$PREFIX/proot/bin/proot"

mkdir -p "$PREFIX/wasm-run/bin"
cp -a "$REPO"/wasm-run/*.js "$REPO"/wasm-run/*.sh "$PREFIX/wasm-run/bin"
cc -DWASM_RUN="\"$PREFIX/wasm-run/bin/wasm-run.js\"" -Wall -O3 "$REPO/wasm-run/qemu-system-wasm32.c" -o "$PREFIX/wasm-run/bin/qemu-system-wasm32"
echo "#!/bin/sh" >> "$PREFIX/wasm-run/bin/wasm-run"
echo "exec $PREFIX/proot/bin/proot -q $PREFIX/wasm-run/bin/qemu-system-wasm32" '${1+"$@"}' >> "$PREFIX/wasm-run/bin/wasm-run"
chmod +x "$PREFIX/wasm-run/bin/wasm-run"

echo "#!/bin/sh" >> "$PREFIX/add_to_github_path.sh"
chmod 755 "$PREFIX/add_to_github_path.sh"

for p in \
  "$PREFIX/wasm-run/bin" \
  "$PREFIX/proot/bin" \
  "$PREFIX/wasm32-wasi-cabal/bin" \
  "$PREFIX/cabal/bin" \
  "$PREFIX/wizer/bin" \
  "$PREFIX/wasmer/bin" \
  "$PREFIX/wasm3/bin" \
  "$PREFIX/toywasm/bin" \
  "$PREFIX/wasmedge/bin" \
  "$PREFIX/iwasm/bin" \
  "$PREFIX/wasmtime/bin" \
  "$PREFIX/wabt/bin" \
  "$PREFIX/binaryen/bin" \
  "$PREFIX/deno/bin" \
  "$PREFIX/wasi-sdk/bin" \
  "$PREFIX/wasm32-wasi-ghc/bin"
do
  echo "export PATH=$p:\$PATH" >> "$PREFIX/env"
  echo "echo $p >> \$GITHUB_PATH" >> "$PREFIX/add_to_github_path.sh"
done

for e in \
  "AR=$PREFIX/wasi-sdk/bin/llvm-ar" \
  "CC=$PREFIX/wasi-sdk/bin/clang" \
  "CC_FOR_BUILD=cc" \
  "CXX=$PREFIX/wasi-sdk/bin/clang++" \
  "LD=$PREFIX/wasi-sdk/bin/wasm-ld" \
  "NM=$PREFIX/wasi-sdk/bin/llvm-nm" \
  "OBJCOPY=$PREFIX/wasi-sdk/bin/llvm-objcopy" \
  "OBJDUMP=$PREFIX/wasi-sdk/bin/llvm-objdump" \
  "RANLIB=$PREFIX/wasi-sdk/bin/llvm-ranlib" \
  "SIZE=$PREFIX/wasi-sdk/bin/llvm-size" \
  "STRINGS=$PREFIX/wasi-sdk/bin/llvm-strings" \
  "STRIP=$PREFIX/wasi-sdk/bin/llvm-strip" \
  "LLC=/bin/false" \
  "OPT=/bin/false"
do
  echo "export $e" >> "$PREFIX/env"
  echo "echo $e >> \$GITHUB_PATH" >> "$PREFIX/add_to_github_path.sh"
done

for e in \
  'CONF_CC_OPTS_STAGE2=${CONF_CC_OPTS_STAGE2:-"-Wno-int-conversion -Wno-strict-prototypes -Wno-implicit-function-declaration -Oz -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mreference-types"}' \
  'CONF_CXX_OPTS_STAGE2=${CONF_CXX_OPTS_STAGE2:-"-Wno-int-conversion -Wno-strict-prototypes -Wno-implicit-function-declaration -fno-exceptions -Oz -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mreference-types"}' \
  'CONF_GCC_LINKER_OPTS_STAGE2=${CONF_GCC_LINKER_OPTS_STAGE2:-"-Wl,--compress-relocations,--error-limit=0,--growable-table,--stack-first,--strip-debug -Wno-unused-command-line-argument"}' \
  'CONF_CC_OPTS_STAGE1=${CONF_CC_OPTS_STAGE1:-"-Wno-int-conversion -Wno-strict-prototypes -Wno-implicit-function-declaration -Oz -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mreference-types"}' \
  'CONF_CXX_OPTS_STAGE1=${CONF_CXX_OPTS_STAGE1:-"-Wno-int-conversion -Wno-strict-prototypes -Wno-implicit-function-declaration -fno-exceptions -Oz -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mreference-types"}' \
  'CONF_GCC_LINKER_OPTS_STAGE1=${CONF_GCC_LINKER_OPTS_STAGE1:-"-Wl,--compress-relocations,--error-limit=0,--growable-table,--stack-first,--strip-debug -Wno-unused-command-line-argument"}' \
  'CONFIGURE_ARGS=${CONFIGURE_ARGS:-"--host=x86_64-linux --target=wasm32-wasi --with-intree-gmp --with-system-libffi"}' \
  'CROSS_EMULATOR=${CROSS_EMULATOR:-"'"$PREFIX/wasm-run/bin/wasmtime.sh"'"}'
do
  echo "export $e" >> "$PREFIX/env"
done

if [ -n "${SKIP_GHC}" ]
then
	exit
fi

mkdir -p "$PREFIX/wasm32-wasi-ghc"
mkdir ghc
curl -f -L --retry 5 "$(jq -r '."wasm32-wasi-ghc-'"$FLAVOUR"'".url' "$REPO"/autogen.json)" | tar xJ -C ghc --strip-components=1
pushd ghc
sh -c ". $PREFIX/env && ./configure \$CONFIGURE_ARGS --prefix=$PREFIX/wasm32-wasi-ghc && make install"
popd

mkdir -p "$PREFIX/cabal/bin"
curl -f -L --retry 5 "$(jq -r .cabal.url "$REPO"/autogen.json)" | tar xJ -C "$PREFIX/cabal/bin" 'cabal'

mkdir -p "$PREFIX/wasm32-wasi-cabal/bin"
echo "#!/bin/sh" >> "$PREFIX/wasm32-wasi-cabal/bin/wasm32-wasi-cabal"
echo \
  "CABAL_DIR=$PREFIX/.cabal" \
  "exec" \
  "$PREFIX/cabal/bin/cabal" \
  "--with-compiler=$PREFIX/wasm32-wasi-ghc/bin/wasm32-wasi-ghc" \
  "--with-hc-pkg=$PREFIX/wasm32-wasi-ghc/bin/wasm32-wasi-ghc-pkg" \
  "--with-hsc2hs=$PREFIX/wasm32-wasi-ghc/bin/wasm32-wasi-hsc2hs" \
  '${1+"$@"}' >> "$PREFIX/wasm32-wasi-cabal/bin/wasm32-wasi-cabal"
chmod +x "$PREFIX/wasm32-wasi-cabal/bin/wasm32-wasi-cabal"

mkdir "$PREFIX/.cabal"
cp "$REPO/cabal.config" "$PREFIX/.cabal/config"
"$PREFIX/wasm32-wasi-cabal/bin/wasm32-wasi-cabal" update

popd

echo "Everything set up in $PREFIX."
echo "Run 'source $PREFIX/env' to add tools to your PATH."
