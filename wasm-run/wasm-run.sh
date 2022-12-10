#!/bin/sh

exec deno run --allow-read --allow-write --v8-flags=--experimental-wasm-return_call,--no-liftoff,--wasm-lazy-compilation,--wasm-lazy-validation ${1+"$@"}
