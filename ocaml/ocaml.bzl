load("//ocaml:repo.bzl", "OPAM_ROOT_DIR", "OCAML_VERSION", "COMPILER_NAME")
OCAML_FILETYPES = FileType([
    ".ml", ".mli", ".cmx", ".cmo", ".cma"
])

_ocaml_toolchain_attrs = {
    "_opam": attr.label(
        default = Label("@opam//:opam"),
        executable = True,
        single_file = True,
        allow_files = True,
        cfg = "host",
    ),
    "_ocamlc": attr.label(
        default = Label("@ocaml_toolchain//:ocamlc"),
        executable = True,
        single_file = True,
        allow_files = True,
        cfg = "host",
    ),
    "_ocamlopt": attr.label(
        default = Label("@ocaml_toolchain//:ocamlopt"),
        executable = True,
        single_file = True,
        allow_files = True,
        cfg = "host",
    ),
    "_ocamlfind": attr.label(
        default = Label("@ocaml_toolchain//:ocamlfind"),
        executable = True,
        single_file = True,
        allow_files = True,
        cfg = "host",
    ),
    "_ocamlbuild": attr.label(
        default = Label("@ocaml_toolchain//:ocamlbuild"),
        executable = True,
        single_file = True,
        allow_files = True,
        cfg = "host",
    )
}

def _ocaml_interface_impl(ctx):
  ctx.actions.run_shell(
      inputs = [ctx.file.src, ctx.executable._ocamlc],
      outputs = [ctx.outputs.mli],
      progress_message = "Compiling interface file %s" % ctx.label,
      mnemonic="OCamlc",
      command = "%s -i -c %s > %s" % (ctx.executable._ocamlc.path, ctx.file.src.path, ctx.outputs.mli.path),
  )

  return struct(mli = ctx.outputs.mli.path)

ocaml_interface = rule(
    implementation = _ocaml_interface_impl,
    attrs = {
        "src": attr.label(
            allow_files = OCAML_FILETYPES,
            single_file = True,
        ),
    } + _ocaml_toolchain_attrs,
    outputs = { "mli": "%{name}.mli" },
)

def _strip_ml_extension(path):
  if path.endswith(".ml"):
    return path[:-3]
  else:
    return path

def _get_src_root(ctx, root_file_names = ["main.ml"]):
  if (ctx.file.src_root != None):
    return ctx.file.src_root
  elif (len(ctx.files.srcs) == 1):
    return ctx.files.srcs[0]
  else:
    for src in ctx.files.srcs:
      if src.basename in root_file_names:
        return src
  fail("No %s source file found." % " or ".join(root_file_names), "srcs")

def _ocaml_binary_impl(ctx):
  ocamlbuild = ctx.executable._ocamlbuild
  ocamlfind = ctx.executable._ocamlfind
  opam = ctx.executable._opam
  opts = "-quiet -build-dir %s" % ctx.outputs.build_dir.path

  src_root = _get_src_root(ctx)
  src = _strip_ml_extension(src_root.path)

  if (ctx.attr.bin_type == "native"):
    target_bin = "%s.native" % src
  else:
    target_bin = "%s.byte" % src

  # Binary compiled by ocamlbuild
  intermediate_bin = "/".join([
      ctx.outputs.build_dir.path,
      target_bin,
  ])

  opam_env_command = "{opam} config exec --root external/ocaml_toolchain/{root_dir} --".format(
        opam = opam.path,
        root_dir = OPAM_ROOT_DIR
  )

  pkgs = ""
  opam_packages = ctx.attr.opam_packages
  if (len(opam_packages) > 0):
    pkgs += "-pkgs " + " ".join(opam_packages) + " -use-ocamlfind"

  command = " ".join([
      opam_env_command,
      ocamlbuild.path,
      opts,
      pkgs,
      target_bin,
      "&& cp -L %s %s" % (intermediate_bin, ctx.outputs.executable.path)
  ])
  print(command)

  ctx.actions.run_shell(
      inputs = ctx.files.srcs + [ocamlfind, ocamlbuild, opam],
      outputs = [ctx.outputs.executable, ctx.outputs.build_dir],
      command = command,
      mnemonic = "Ocamlbuild",
      progress_message = "Compiling OCaml binary %s" % ctx.label.name,
      # This is (unfortunately) not hermetic yet.
      use_default_shell_env = True,
      execution_requirements = {"local": "1"},
  )

_ocaml_binary = rule(
    implementation = _ocaml_binary_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = OCAML_FILETYPES
        ),
        "deps": attr.label_list(),
        "src_root": attr.label(
            allow_files = OCAML_FILETYPES,
            single_file = True,
            mandatory = True,
        ),
        "opam_packages": attr.string_list(default = []),
        "bin_type": attr.string(default = "native")
    } + _ocaml_toolchain_attrs,
    executable = True,
    outputs = { "build_dir": "_build_%{name}" },
)

def ocaml_native_binary(**kwargs):
  _ocaml_binary(bin_type = "native", **kwargs)

def ocaml_bytecode_binary(**kwargs):
  _ocaml_binary(bin_type = "bytecode", **kwargs)
