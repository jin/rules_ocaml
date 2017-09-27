OCAML_FILETYPES = FileType([".ml"])
OCAML_VERSION = "4.03.0"

_opam_binary_attrs = {
    "_opam": attr.label(
        default = Label("@opam//:opam"),
        executable = True,
        single_file = True,
        allow_files = True,
        cfg = "host",
    ),
}

_ocaml_toolchain_attrs = {
    "_ocamlc": attr.label(
        default = Label("@ocaml_toolchain//:ocamlc"),
        executable = True,
        single_file = True,
        allow_files = True,
        cfg = "host",
    )
} + _opam_binary_attrs

def _ocaml_interface_impl(ctx):
  ctx.run_shell(
      # executable = ctx.executable._ocamlc,
      # arguments = ["-i", "-c"], #, "-o", ctx.outputs.mli.path, ctx.file.src.path],
      inputs = [ctx.file.src],
      outputs = [ctx.outputs.mli],
      progress_message = "ocaml %s" % ctx.label,
      mnemonic="OCamlc",
      command = "ocamlc -i -c %s > %s" % (ctx.file.src, ctx.outputs.mli),
  )

  return struct(mli = ctx.outputs.mli)

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
  src_root = _get_src_root(ctx)
  src = _strip_ml_extension(src_root.path)
  ocamlbuild_bin = "ocamlbuild"
  opts = "-build-dir %s" % ctx.outputs.build_dir.path

  opam_path = ctx.executable._opam
  print(opam_path)

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

  mv_command = "&& cp -L %s %s" % (intermediate_bin, ctx.outputs.executable.path)
  command = " ".join([ocamlbuild_bin, opts, pkgs, target_bin, mv_command])

  ctx.action(
      inputs = ctx.files.srcs,
      command = command,
      outputs = [ctx.outputs.executable, ctx.outputs.build_dir],
      use_default_shell_env=True,
      progress_message = "Compiling OCaml binary %s" % ctx.label.name,
  )

_ocaml_binary = rule(
    implementation = _ocaml_binary_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = OCAML_FILETYPES
        ),
        "src_root": attr.label(
            allow_files = OCAML_FILETYPES,
            single_file = True,
            mandatory = False,
        ),
        "opam_packages": attr.string_list(mandatory = False),
        "bin_type": attr.string(default = "native"),
    } + _ocaml_toolchain_attrs,
    executable = True,
    outputs = {
       "build_dir": "_build_%{name}"
    },
)

def ocaml_native_binary(name, srcs, **kwargs):
  _ocaml_binary(
      name = name,
      srcs = srcs,
      bin_type = "native",
      **kwargs
  )

def ocaml_bytecode_binary(name, srcs, **kwargs):
  _ocaml_binary(
      name = name,
      srcs = srcs,
      bin_type = "bytecode",
      **kwargs
  )

# Set up OCaml's toolchain (ocamlc, ocamlbuild, ocamlfind)
_OCAML_TOOLCHAIN_BUILD = """
filegroup(
  name = "ocamlc",
  srcs = ["opam_dir/4.03.0/bin/ocamlc"],
  visibility = ["//visibility:public"],
)
 
filegroup(
  name = "ocamlbuild",
  srcs = ["opam_dir/4.03.0/bin/ocamlbuild"],
  visibility = ["//visibility:public"],
)
"""

def _ocaml_toolchain_impl(repository_ctx):
  opam_dir = "opam_dir"
  opam_path = repository_ctx.path(repository_ctx.attr._opam)
  repository_ctx.execute([opam_path, "init", "--root", opam_dir, "--no-setup"], quiet = False)
  repository_ctx.execute([opam_path, "switch", "create", "4.03.0", "ocaml-base-compiler.4.03.0", "--root", opam_dir], quiet = False)
  repository_ctx.execute([opam_path, "install", "ocamlbuild", "--yes", "--root", opam_dir], quiet = False)
  # repository_ctx.execute([opam_path, "install", "ocamlbuild", "--yes", "--root", opam_dir], quiet = False)
  repository_ctx.file("WORKSPACE", "", False)
  repository_ctx.file("BUILD", _OCAML_TOOLCHAIN_BUILD, False)

_ocaml_toolchain = repository_rule(
    implementation = _ocaml_toolchain_impl,
    attrs = _opam_binary_attrs,
)

def ocaml_toolchain():
  _ocaml_toolchain(name = "ocaml_toolchain")

# Set up OPAM
def _opam_binary_impl(repository_ctx):
  os_name = repository_ctx.os.name.lower()
  if os_name.find("windows") != -1:
    fail("Windows is not supported yet, sorry!")
  elif os_name.startswith("mac os"):
    repository_ctx.download(
        "https://github.com/ocaml/opam/releases/download/2.0-alpha4/opam-2.0-alpha4-x86_64-Darwin",
        "opam",
        "70120e5ded040ddad16914ee56180a2be9c7d64e332f16f7a6f47c41069d9e93",
        executable = True,
    )
  else:
    repository_ctx.download(
        "https://github.com/ocaml/opam/releases/download/2.0-alpha4/opam-2.0-alpha4-x86_64-Linux",
        "opam",
        "3171aa1b10df13aa657cffdd5c616f8e5a7c624f8335de72db2e28db51435fe0",
        executable = True,
    )
  repository_ctx.file("WORKSPACE", "", False)
  repository_ctx.file("BUILD", "exports_files([\"opam\"])", False)

_opam_binary = repository_rule(
    implementation = _opam_binary_impl,
    attrs = {}
)

def opam_binary():
  _opam_binary(name = "opam")

def ocaml_repositories():
  opam_binary()
  ocaml_toolchain()
