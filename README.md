# `ghc-wasm-meta`

This repo provides convenient methods of using x86_64-linux binary
artifacts of GHC's wasm backend.

## Getting started as a nix flake

This repo is a nix flake. The default output is a derivation that
bundles all provided tools:

```sh
$ nix shell https://gitlab.haskell.org/ghc/ghc-wasm-meta/-/archive/master/ghc-wasm-meta-master.tar.gz
$ echo 'main = putStrLn "hello world"' > hello.hs
$ wasm32-wasi-ghc hello.hs -o hello.wasm
[1 of 2] Compiling Main             ( hello.hs, hello.o )
[2 of 2] Linking hello.wasm
$ wasmtime ./hello.wasm
hello world
```

First start will download a bunch of stuff, but won't take too long
since it just patches the binaries and performs little real
compilation. There is no need to set up a binary cache.

## Getting started without nix

For Ubuntu 20.04 and similar glibc-based distros, this repo provides a
`setup.sh` script that installs the provided tools to `~/.ghc-wasm`:

```sh
$ ./setup.sh
...
Everything set up in /home/username/.ghc-wasm.
Run 'source /home/username/.ghc-wasm/env' to add tools to your PATH.
```

After installing, `~/.ghc-wasm` will contain:

  - `env` which can be sourced into the current shell to add the tools
    to `PATH`
  - `add_to_github_path.sh` which can be run in GitHub actions, so
    later steps in the same job can access the tools from `PATH`

`setup.sh` can be configured via these environment variables:

  - `PREFIX`: installation destination, defaults to `~/.ghc-wasm`
  - `BIGNUM_BACKEND`: which `ghc-bignum` backend to use, can be either
    `gmp` or `native`, defaults to `gmp`
  - `SKIP_GHC`: set this to skip installing `cabal` and `ghc`

`setup.sh` requires `cc`, `curl`, `jq`, `unzip` to run.

## What it emits when it emits a `.wasm` file?

Besides wasm MVP, these extensions are used, given they have been
supported by default in latest versions of major wasm runtimes:

- nontrapping-fptoint
- sign-ext
- bulk-memory
- mutable-globals
- reference-types

The target triple is `wasm32-wasi`, and it uses WASI snapshot 1 as
used in `wasi-libc`.

## What runtimes support those `.wasm` files?

The output `.wasm` modules are known to run on latest versions of at
least these runtimes:

- [`wasmtime`](https://wasmtime.dev)
- [`wasmedge`](https://wasmedge.org)
- [`wasmer`](https://wasmer.io)
- [`wasm3`](https://github.com/wasm3/wasm3) (needs latest `main`
  revision)
- [`deno`](https://deno.land) (using
  [`wasi`](https://deno.land/std/wasi/snapshot_preview1.ts) as WASI
  implementation)
- [`node`](https://nodejs.org)

## Accessing the host file system

By default, only stdin/stdout/stderr is supported. To access the host
file system, one needs to map the allowed root directory into `/` as a
WASI preopen.

The initial working directoy is always `/`. If you'd like to specify
another working directory other than `/` in the virtual filesystem,
use the `PWD` environment variable. This is not a WASI standard, just
a workaround we implemented in the GHC RTS shall the need arises.

## Reporting issues

For reporting issues, please use the GHC issue tracker instead. Issues
with the `wasm` tag will be sent to the GHC wasm backend maintainer.
