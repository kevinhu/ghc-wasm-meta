#!/bin/sh

exec wasmtime run -C cache=n -C parallel-compilation=n --env PATH= --env PWD="$PWD" --dir /::/ -O opt-level=0 -W tail-call -- ${1+"$@"}
