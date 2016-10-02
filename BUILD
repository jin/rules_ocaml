load("//ocaml:ocaml.bzl", "ocaml_native_binary", "ocaml_interface")

ocaml_native_binary(
    name = "hello_world",
    srcs = glob(["examples/*.ml"]),
    src_root = "examples/hello_world.ml",
)

ocaml_interface(
    name = "test",
    src = "examples/test.ml",
)
