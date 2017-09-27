load("//ocaml:ocaml.bzl", "ocaml_native_binary", "ocaml_interface")

ocaml_native_binary(
    name = "hello_world",
    srcs = glob(["*.ml"]),
    src_root = "hello_world.ml",
)

ocaml_interface(
    name = "test",
    src = "test.ml",
)
