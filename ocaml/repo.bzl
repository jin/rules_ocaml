OCAML_VERSION = "4.04.0"
OCAMLBUILD_VERSION = "0.11.0"
OCAMLFIND_VERSION = "1.7.3"
COMPILER_NAME = "ocaml-base-compiler.%s" % OCAML_VERSION

# Set to false to see debug messages
DEBUG_QUIET = True

# The path to the root opam directory
OPAM_ROOT_DIR = "OPAM_ROOT_DIR"

# Set up OCaml's toolchain (ocamlc, ocamlbuild, ocamlfind)
_OCAML_TOOLCHAIN_BUILD = """
filegroup(
  name = "ocamlc",
  srcs = ["{opam_dir}/{compiler}/bin/ocamlc"],
  visibility = ["//visibility:public"],
)

filegroup(
  name = "ocamlopt",
  srcs = ["{opam_dir}/{compiler}/bin/ocamlopt"],
  visibility = ["//visibility:public"],
)

filegroup(
  name = "ocamlfind",
  srcs = ["{opam_dir}/{compiler}/bin/ocamlfind"],
  visibility = ["//visibility:public"],
)

filegroup(
  name = "ocamlbuild",
  srcs = ["{opam_dir}/{compiler}/bin/ocamlbuild"],
  visibility = ["//visibility:public"],
)
""".format(
    compiler = COMPILER_NAME,
    opam_dir = OPAM_ROOT_DIR
)

def _ocaml_toolchain_impl(repository_ctx):
  opam_bin = repository_ctx.path(repository_ctx.attr._opam)

  # Initialize opam and its root directory
  repository_ctx.execute([
      opam_bin,
      "init",
      "--root", OPAM_ROOT_DIR,
      "--no-setup",
      "--comp", COMPILER_NAME
  ], quiet = DEBUG_QUIET)

  # Download the OCaml compiler
  repository_ctx.execute([
      opam_bin,
      "switch", COMPILER_NAME,
      "--root", OPAM_ROOT_DIR
  ], quiet = DEBUG_QUIET)

  # Install OCamlbuild
  repository_ctx.execute([
      opam_bin,
      "install",
      "ocamlbuild=%s" % OCAMLBUILD_VERSION,
      "--yes",
      "--root", OPAM_ROOT_DIR
  ], quiet = DEBUG_QUIET)

  # Install OCamlfind
  repository_ctx.execute([
      opam_bin,
      "install",
      "ocamlfind=%s" % OCAMLFIND_VERSION,
      "--yes",
      "--root", OPAM_ROOT_DIR
  ], quiet = DEBUG_QUIET)

  [repository_ctx.execute([
      opam_bin,
      "install",
      "%s=%s" % (pkg, version),
      "--yes",
      "--root", OPAM_ROOT_DIR
  ], quiet = DEBUG_QUIET)
   for (pkg, version) in repository_ctx.attr.opam_packages.items()]

  repository_ctx.file("WORKSPACE", "", False)
  repository_ctx.file("BUILD", _OCAML_TOOLCHAIN_BUILD, False)

_ocaml_toolchain_repo = repository_rule(
    implementation = _ocaml_toolchain_impl,
    attrs = {
        "_opam": attr.label(
            default = Label("@opam//:opam"),
            executable = True,
            single_file = True,
            allow_files = True,
            cfg = "host",
        ),
        "opam_packages": attr.string_dict(default = {}),
    }
)

def _ocaml_toolchain(opam_packages = []):
  _ocaml_toolchain_repo(
      name = "ocaml_toolchain",
      opam_packages = opam_packages,
  )

# Set up OPAM
def _opam_binary_impl(repository_ctx):
  os_name = repository_ctx.os.name.lower()
  if os_name.find("windows") != -1:
    fail("Windows is not supported yet, sorry!")
  elif os_name.startswith("mac os"):
    repository_ctx.download(
        "https://github.com/ocaml/opam/releases/download/2.0.0-beta4/opam-2.0.0-beta4-x86_64-darwin",
        "opam",
        "d23c06f4f03de89e34b9d26ebb99229a725059abaf6242ae3b9e9bf946b445e1",
        executable = True,
    )
  else:
    repository_ctx.download(
        "https://github.com/ocaml/opam/releases/download/2.0.0-beta4/opam-2.0.0-beta4-x86_64-linux",
        "opam",
        "3de4b78a263d4c1e46760c26bdc2b02fdbce980a9fc9141385058c2b0174708c",
        executable = True,
    )
  repository_ctx.file("WORKSPACE", "", False)
  repository_ctx.file("BUILD", "exports_files([\"opam\"])", False)

_opam_binary_repo = repository_rule(
    implementation = _opam_binary_impl,
    attrs = {}
)

def _opam_binary():
  _opam_binary_repo(name = "opam")

def ocaml_repositories(opam_packages = {}):
  _opam_binary()
  _ocaml_toolchain(opam_packages = opam_packages)
