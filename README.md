# OCaml rules for Bazel

## Rules

* [ocaml_native_binary](#ocaml_native_binary)
* [ocaml_bytecode_binary](#ocaml_bytecode_binary)
* [ocaml_interface](#ocaml_interface)

## Overview

Build OCaml with Bazel. Very experimental.

## Setup

This is a wrapper around `ocamlbuild`. Ensure that your `ocamlbuild` and `ocamlfind` are reachable in your `PATH`.

Add the following to your `WORKSPACE` file.

```bzl
git_repository(
    name = "io_bazel_rules_ocaml",
    remote = "https://github.com/jin/rules_ocaml.git",
    commit = "695034b70643dab296725a26a05c494969edf727",
)
```

and this to your BUILD files.

```bzl
load("@io_bazel_rules_ocaml//ocaml:ocaml.bzl", "ocaml_native_binary", "ocaml_bytecode_binary")
```

## Examples

### ocaml_native_binary

Generates a native binary.

```bzl
ocaml_native_binary(
    name = "hello_world",
    src = "examples/hello_world.ml",
    opam_pkgs = ["pkg_foo", "pkg_bar"]
)
```

### ocaml_bytecode_binary

Generates a bytecode binary.

```bzl
ocaml_bytecode_binary(
    name = "hello_world",
    src = "examples/hello_world.ml",
    opam_pkgs = ["pkg_foo", "pkg_bar"]
)
```

### ocaml_interface

Generates a `.mli` file of the source.

```bzl
ocaml_interface(
    name = "hello_world_interface",
    src = "examples/hello_world.ml",
)
```
