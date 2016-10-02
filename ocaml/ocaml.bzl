OCAML_FILETYPES = FileType([".ml"])

def _ocaml_interface_impl(ctx):
  ctx.action(
      inputs = [ctx.file.src],
      outputs = [ctx.outputs.mli],
      command = "ocamlc -i -c %s > %s" % (ctx.file.src.path, ctx.outputs.mli.path),
  )

ocaml_interface = rule(
    implementation = _ocaml_interface_impl,
    attrs = {
        "src": attr.label(
            allow_files = OCAML_FILETYPES,
            single_file = True,
        ),
    },
    outputs = { "mli": "%{name}.mli" },
)

def _strip_ml_extension(path):
  if path.endswith(".ml"):
    return path[:-3]
  else:
    return path


def _ocaml_binary_impl(ctx):
  src = _strip_ml_extension(ctx.file.src.path)
  ocamlbuild_bin = "rm -rf _build && ocamlbuild"
  opts = "-r"

  if (ctx.attr.bin_type == "native"):
    target_bin = "%s.native" % src
  else:
    target_bin = "%s.byte" % src

  dirname = ctx.file.src.dirname
  intermediate_bin = target_bin.replace(dirname + "/", "")

  pkgs = ""
  if (len(ctx.attr.opam_pkgs) > 0):
    pkgs = "-pkgs " + " ".join(ctx.attr.opam_pkgs) + " -use-ocamlfind"

  # Move the binary into bazel-out
  mv_command = "&& cp -L %s %s" % (intermediate_bin, ctx.outputs.bin.path)
  command = " ".join([ocamlbuild_bin, opts, pkgs, target_bin, mv_command])

  ctx.action(
      inputs = ctx.files.src,
      command = command,
      outputs = [ctx.outputs.bin],
      use_default_shell_env=True,
      progress_message = "Compiling OCaml binary %s" % ctx.label.name,
  )

_ocaml_binary = rule(
    implementation = _ocaml_binary_impl,
    attrs = {
        "src": attr.label(
            allow_files=OCAML_FILETYPES,
            single_file=True,
        ),
        "opam_pkgs": attr.string_list(mandatory=False),
        "bin_type": attr.string(default="native"),
    },
    outputs = { "bin": "%{name}.out" },
)

def ocaml_native_binary(name, src, **kwargs):
  _ocaml_binary(
      name = name,
      src = src,
      bin_type = "native",
      **kwargs
  )

def ocaml_bytecode_binary(name, src, **kwargs):
  _ocaml_binary(
      name = name,
      src = src,
      bin_type = "bytecode",
      **kwargs
  )
