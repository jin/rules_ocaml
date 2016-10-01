_OCAML_FILETYPES = FileType([".ml"])

def _ocaml_binary_impl(ctx):
  ctx.action(
      inputs = [ctx.file.src],
      outputs = [ctx.outputs.binary],
      command = "ocamlc -o %s %s" % (ctx.outputs.binary.path, ctx.file.src.path),
  )

ocaml_binary = rule(
    implementation = _ocaml_binary_impl,
    attrs = {
        "src": attr.label(
            allow_files=_OCAML_FILETYPES,
            single_file=True,
        ),
    },
    outputs = { "binary": "%{name}.native" },
)
