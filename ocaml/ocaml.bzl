OCAML_FILETYPES = FileType([".ml"])
OCAML_VERSION = "4.03.0"

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
  opts = "-quiet -build-dir %s" % ctx.outputs.build_dir.path

  src_root = _get_src_root(ctx)
  src = _strip_ml_extension(src_root.path)

  if (ctx.attr.bin_type == "native"):
    target_bin = "%s.native" % src
  else:
    target_bin = "%s.byte" % src

  # Binary compiled by ocamlbuild
  intermediate_bin = "/".join([ctx.outputs.build_dir.path, target_bin])

  # opam_command = ""
  pkgs = ""
  # opam_packages = ctx.attr.opam_packages
  # if (len(opam_packages) > 0):
  #   pkgs += "-pkgs " + " ".join(ctx.attr.opam_packages) + " -use-ocamlfind"
  #   opam_command = " ".join([opam_path, "install"] + opam_packages + ["ocamlbuild", "&&"])

  ctx.action(
      inputs = ctx.files.srcs + [ocamlbuild],
      outputs = [ctx.outputs.executable, ctx.outputs.build_dir],
      command = " ".join([
          ocamlbuild.path, 
          opts, pkgs, 
          target_bin, 
          "&& cp -L %s %s" % (intermediate_bin, ctx.outputs.executable.path)
      ]),
      use_default_shell_env = True,
      mnemonic = "Ocamlbuild",
      progress_message = "Compiling OCaml binary %s" % ctx.label.name,
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
    } + _ocaml_toolchain_attrs,
    executable = True,
    outputs = { },
)

def ocaml_native_binary(name, srcs):
  _ocaml_binary(
      name = name,
      srcs = srcs,
      compiler = "@ocaml_toolchain//:ocamlopt",
  )

def ocaml_bytecode_binary(name, srcs):
  _ocaml_binary(
      name = name,
      srcs = srcs,
      compiler = "@ocaml_toolchain//:ocamlc",
  )
