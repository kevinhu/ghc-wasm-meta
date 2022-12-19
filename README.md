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
    to `PATH`, plus all the environment variables needed to build
    `wasm32-wasi-ghc`
  - `add_to_github_path.sh` which can be run in GitHub actions, so
    later steps in the same job can access the same environment
    variables set by `env`

`setup.sh` can be configured via these environment variables:

  - `PREFIX`: installation destination, defaults to `~/.ghc-wasm`
  - `BIGNUM_BACKEND`: which `ghc-bignum` backend to use, can be either
    `gmp` or `native`, defaults to `gmp`
  - `SKIP_GHC`: set this to skip installing `cabal` and `ghc`

`setup.sh` requires `cc`, `curl`, `jq`, `unzip` to run.

## What it emits when it emits a `.wasm` file?

Besides wasm MVP, certain extensions are used. The feature flags are
enabled globally in our
[wasi-sdk](https://gitlab.haskell.org/ghc/wasi-sdk) build, passed at
GHC configure time, and the wasm NCG may make use of the features. The
rationale of post-MVP wasm feature inclusion:

- Supported by default in latest versions of major wasm runtimes
(check wasm [roadmap](https://webassembly.org/roadmap) for details)
- LLVM support has been stable enough (doesn't get into our way when
enabled globally)

List of wasm extensions that we use:

- [Non-trapping Float-to-int
  Conversions](https://github.com/WebAssembly/spec/blob/master/proposals/nontrapping-float-to-int-conversion/Overview.md)
- [Sign-extension
  operators](https://github.com/WebAssembly/spec/blob/master/proposals/sign-extension-ops/Overview.md)
- [Bulk Memory
  Operations](https://github.com/WebAssembly/spec/blob/master/proposals/bulk-memory-operations/Overview.md)
- [Import/Export mutable
  globals](https://github.com/WebAssembly/mutable-global/blob/master/proposals/mutable-global/Overview.md)
- [Reference
  Types](https://github.com/WebAssembly/spec/blob/master/proposals/reference-types/Overview.md)

The target triple is `wasm32-wasi`, and it uses WASI snapshot 1 as
used in `wasi-libc`.

List of wasm extensions that we don't use yet but are keeping an eye
on:

- [128-bit packed
  SIMD](https://github.com/WebAssembly/spec/blob/master/proposals/simd/SIMD.md),
  blocked by [WebKit](https://bugs.webkit.org/show_bug.cgi?id=222382)
- [Tail
  Call](https://github.com/WebAssembly/tail-call/blob/main/proposals/tail-call/Overview.md),
  blocked by
  [wasmtime](https://github.com/bytecodealliance/wasmtime/issues/1065)
  and a few other engines
- [Multi-value](https://github.com/WebAssembly/spec/blob/master/proposals/multi-value/Overview.md),
  blocked by [LLVM](https://github.com/llvm/llvm-project/issues/59095)

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

## Running in browsers

According to the [Roadmap](https://webassembly.org/roadmap), recent
versions of Firefox/Chrome/Safari also support them, as long as you
have corresponding JavaScript code to supply the wasi imports. Known
examples include
[`ormolu`](https://twitter.com/tweagio/status/1598618914761719808) and
[`pointfree`](https://www.reddit.com/r/haskell/comments/zc8o75/try_the_wasm_port_of_pointfree).
We don't have an official recommendation about which JavaScript
library to use for wasi logic yet, hopefully some time later we'll
have one which is tested in headless browsers.

Important points to keep in mind when running in browsers:

- Always create a fresh `WebAssembly.Instance` for each run! Because
  `wasm32-wasi-ghc` only supports outputting wasi
  [command](https://github.com/WebAssembly/WASI/blob/main/legacy/application-abi.md)
  modules for now, and wasi commands are supposed to be only run once,
  afterwards the instance state is undefined.
- Avoid recompiling the module multiple times; the same
  `WebAssembly.Module` can be reused many times.
- For now, the recommended workflow is using
  [`WebAssembly.compileStreaming`](https://developer.mozilla.org/en-US/docs/WebAssembly/JavaScript_interface/compileStreaming)
  to get a `WebAssembly.Module`, then use
  [`WebAssembly.instantiate`](https://developer.mozilla.org/en-US/docs/WebAssembly/JavaScript_interface/instantiate)
  to get the `WebAssembly.Instance` for each run.

## Accessing the host file system in non-browsers

By default, only stdin/stdout/stderr is supported. To access the host
file system, one needs to map the allowed root directory into `/` as a
WASI preopen.

The initial working directoy is always `/`. If you'd like to specify
another working directory other than `/` in the virtual filesystem,
use the `PWD` environment variable. This is not a WASI standard, just
a workaround we implemented in the GHC RTS shall the need arises.

## Building guide

If you intend to build the GHC's wasm backend, here's a building
guide, assuming you already have some experience with building native
GHC.

### Install `wasi-sdk`

To build the wasm backend, the systemwide C/C++ toolchain won't work.
You need to install our `wasi-sdk`
[fork](https://gitlab.haskell.org/ghc/wasi-sdk). Upstream `wasi-sdk`
won't work yet.

If your host system is one of `{x86_64,aarch64}-{linux,darwin}`, then
you can avoid building and simply download & extract the GitLab CI
artifact from the latest `master` commit. The linux artifacts are
statically linked and work out of the box on all distros; the macos
artifact contains universal binaries and works on either apple silicon
or intel mac.

If your host system is `x86_64-linux`, you can use the `setup.sh`
script to install it, as documented in previous sections.

For simplicity, the following subsections all assume `wasi-sdk` is
installed to `~/.ghc-wasm/wasi-sdk`, and
`~/.ghc-wasm/wasi-sdk/bin/clang` works.

### Install `libffi-wasm`

Skip this subsection if `wasi-sdk` is installed by `setup.sh` instead
of extracting CI artifacts directly.

Extract the CI artifact of
[`libffi-wasm`](https://gitlab.haskell.org/ghc/libffi-wasm), and copy
its contents:

- `cp *.h ~/.ghc-wasm/wasi-sdk/share/wasi-sysroot/include`
- `cp *.a ~/.ghc-wasm/wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi`

### Set environment variables

If you used `setup.sh` to install `wasi-sdk`/`libffi-wasm`, then you
can `source ~/.ghc-wasm/env` into your current shell to set the
following environment variables required for building. Otherwise, you
can save this to somewhere else and source that script.

```bash
export AR=~/.ghc-wasm/wasi-sdk/bin/llvm-ar
export CC=~/.ghc-wasm/wasi-sdk/bin/clang
export CC_FOR_BUILD=cc
export CXX=~/.ghc-wasm/wasi-sdk/bin/clang++
export LD=~/.ghc-wasm/wasi-sdk/bin/wasm-ld
export NM=~/.ghc-wasm/wasi-sdk/bin/llvm-nm
export OBJCOPY=~/.ghc-wasm/wasi-sdk/bin/llvm-objcopy
export OBJDUMP=~/.ghc-wasm/wasi-sdk/bin/llvm-objdump
export RANLIB=~/.ghc-wasm/wasi-sdk/bin/llvm-ranlib
export SIZE=~/.ghc-wasm/wasi-sdk/bin/llvm-size
export STRINGS=~/.ghc-wasm/wasi-sdk/bin/llvm-strings
export STRIP=~/.ghc-wasm/wasi-sdk/bin/llvm-strip
export CONF_CC_OPTS_STAGE2="-Wno-int-conversion -Wno-strict-prototypes -Oz -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mreference-types"
export CONF_CXX_OPTS_STAGE2="-Wno-int-conversion -Wno-strict-prototypes -fno-exceptions -Oz -mnontrapping-fptoint -msign-ext -mbulk-memory -mmutable-globals -mreference-types"
export CONF_GCC_LINKER_OPTS_STAGE2="-Wl,--compress-relocations,--error-limit=0,--growable-table,--stack-first,--strip-debug -Wno-unused-command-line-argument"
export CONFIGURE_ARGS="--target=wasm32-wasi --with-intree-gmp --with-system-libffi"
```

### Checkout & patch GHC

Checkout GHC. Latest `master` revision contains wasm backend support.
Do apply the patches
[here](https://gitlab.haskell.org/ghc/ghc/-/blob/cc25d52e0f65d54c052908c7d91d5946342ab88a/.gitlab-ci.yml#L816),
they may get removed some time later but for now they're mandatory to
get the wasm backend building.

### Boot & configure & build GHC

The rest is the usual boot & configure & build process. You need to
ensure the environment variables described earlier are correctly set
up; for `ghc.nix` users, it sets up a default `CONFIGURE_ARGS` in the
nix-shell which is incompatible, and the `env` script set up by
`setup.sh` respects existing `CONFIGURE_ARGS`, so don't forget to
unset it first!

Configure with `./configure $CONFIGURE_ARGS`, then build with hadrian.
After the build completes, you can compile stuff to wasm using
`_build/stage1/bin/wasm32-wasi-ghc`.

Happy hacking!

## Reporting issues

For reporting issues, please use the GHC issue tracker instead. Issues
with the `wasm` tag will be sent to the GHC wasm backend maintainer.
