package(default_visibility = ["//visibility:public"])

config_setting(
    name = "darwin",
    values = {"host_cpu": "darwin"},
)

config_setting(
    name = "k8",
    values = {"host_cpu": "k8"},
)

filegroup(
    name = "opam",
    srcs = select({
        ":darwin": ["@opam_darwin_x86_64//file"],
        ":k8": ["@opam_linux_x86_64//file"],
    }),
)
