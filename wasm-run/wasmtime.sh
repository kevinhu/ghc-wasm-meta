#!/bin/sh

exec wasmtime run --disable-cache --disable-parallel-compilation --env PATH= --env PWD="$PWD" --mapdir /::/ --opt-level 0 --wasm-features tail-call -- ${1+"$@"}
