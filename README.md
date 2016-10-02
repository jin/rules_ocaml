# OCaml rules for Bazel

## Rules

* [ocaml_native_binary](#ocaml_native_binary)
* [ocaml_bytecode_binary](#ocaml_bytecode_binary)
* [ocaml_interface](#ocaml_interface)

## Overview

Build OCaml with Bazel. Very experimental.

## Setup

This is a wrapper around `ocamlbuild`. Ensure that your `ocamlbuild` and `ocamlfind` are reachable in your `PATH`.

Add the following to your `WORKSPACE` file to add the external repositories:

TODO

## Examples

### ocaml_native_binary

Generates a native binary.

```python
ocaml_native_binary(
    name = "hello_world",
    src = "examples/hello_world.ml",
    opam_pkgs = ["pkg_foo", "pkg_bar"]
)
```

### ocaml_bytecode_binary

Generates a bytecode binary.

```python
ocaml_bytecode_binary(
    name = "hello_world",
    src = "examples/hello_world.ml",
    opam_pkgs = ["pkg_foo", "pkg_bar"]
)
```

### ocaml_interface

Generates a `.mli` file of the source.

```python
ocaml_interface(
    name = "hello_world_interface",
    src = "examples/hello_world.ml",
)
```
