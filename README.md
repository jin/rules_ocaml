# OCaml rules for Bazel

## Rules

* [ocaml_native_binary](#ocaml_native_binary/ocaml_bytecode_binary)
* [ocaml_bytecode_binary](#ocaml_native_binary/ocaml_bytecode_binary)
* [ocaml_interface](#ocaml_interface)

## Overview

Build OCaml with Bazel. Very experimental. API is expected to change.

## Setup

Add the following to your `WORKSPACE` file.

```bzl
git_repository(
    name = "io_bazel_rules_ocaml",
    remote = "https://github.com/jin/rules_ocaml.git",
    commit = "18685e1bc5ad22e425f502355087747a6638f51a",
)

load("@io_bazel_rules_ocaml//ocaml:repo.bzl", "ocaml_repositories")
ocaml_repositories(
    opam_packages = {
        # Put your OPAM dependencies here
        "lwt": "3.1.0",
        "yojson": "1.4.0",
    },
)
```

and this to your BUILD files.

```bzl
load("@io_bazel_rules_ocaml//ocaml:ocaml.bzl", "ocaml_native_binary", "ocaml_bytecode_binary", "ocaml_interface")
```

## Rules

### ocaml_native_binary/ocaml_bytecode_binary

Generates a native binary using `ocamlopt` or bytecode binary using `ocamlc`.

```bzl
ocaml_native_library(name, srcs, src_root, opam_packages)
ocaml_bytecode_library(name, srcs, src_root, opam_packages)
```

#### Example

```bzl
ocaml_native_binary(
    name = "hello_world",
    srcs = glob(["examples/*.ml"]),
    src_root = "examples/hello_world.ml",
    opam_packages = ["pkg_foo", "pkg_bar"],
)

ocaml_bytecode_binary(
    name = "other_binary",
    srcs = [
      "examples/foo.ml",
      "examples/bar.ml",
      "examples/entry.ml",
    ],
    src_root = "examples/entry.ml",
    opam_packages = ["pkg_foo", "pkg_bar"],
)
```

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name, required</code></p>
        <p>A unique name for this target</p>
      </td>
    </tr>
    <tr>
      <td><code>srcs</code></td>
      <td>
        <p><code>List of labels, required</code></p>
        <p>List of OCaml <code>.ml</code> source files used to build the
        library</p>
      </td>
    </tr>
    <tr>
      <td><code>src_root</code></td>
      <td>
        <p><code>Label, optional</code></p>
        <p>The OCaml <code>.ml</code> source file used for the binary's entry point.<p>
        <p>Defaults to <code>main.ml</code> if not specified.
      </td>
    </tr>
    <tr>
      <td><code>opam_packages</code></td>
      <td>
        <p><code>List of strings, optional</code></p>
        <p>The name of the OPAM package dependencies required by this binary.</p>
        <p>The packages (and their versions) must already be defined in your WORKSPACE file's <code>ocaml_repositories()</code>.
      </td>
    </tr>
  </tbody>
</table>

### ocaml_interface

Generates a `.mli` file of the source file.

```bzl
ocaml_interface(name, src)
```

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <p><code>Name, required</code></p>
        <p>A unique name for this target</p>
      </td>
    </tr>
    <tr>
      <td><code>src</code></td>
      <td>
        <p><code>Label</code></p>
        <p>The OCaml <code>.ml</code> source file used for generating the interface file<p>
      </td>
    </tr>
  </tbody>
</table>

#### Example

```bzl
ocaml_interface(
    name = "hello_world_interface",
    src = "examples/hello_world.ml",
)
```

## Projects using rules_ocaml

- [https://github.com/jin/scheme.ml](https://github.com/jin/scheme.ml)
