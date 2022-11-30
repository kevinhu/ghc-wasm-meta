#!/usr/bin/env -S deno run --allow-read --allow-write --v8-flags=--no-liftoff,--wasm-lazy-compilation,--wasm-lazy-validation

import WasiContext from "https://deno.land/std@0.166.0/wasi/snapshot_preview1.ts";
import * as path from "https://deno.land/std@0.166.0/path/mod.ts";

function parseArgv(args) {
  const i = args.indexOf("-0");
  return args.slice(i + 2);
}

const argv = parseArgv(Deno.args);
const argv0 = await Deno.realPath(argv[0]);

const context = new WasiContext({
  args: argv,
  env: { PATH: "" },
  preopens: { "/": path.parse(argv0).dir },
});

const instance = (
  await WebAssembly.instantiate(await Deno.readFile(argv0), {
    wasi_snapshot_preview1: context.exports,
  })
).instance;

context.start(instance);
