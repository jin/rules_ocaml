load("//ocaml:ocaml.bzl", "ocaml_native_binary", "ocaml_bytecode_binary", "ocaml_interface")

ocaml_native_binary(
    name = "hello_world_native",
    srcs = [
        "test.ml", 
        "hello_world.ml",
    ],
)

ocaml_bytecode_binary(
    name = "hello_world_bytecode",
    srcs = [
        "test.ml", 
        "hello_world.ml",
    ],
)

ocaml_interface(
    name = "test",
    src = "test.ml",
)
