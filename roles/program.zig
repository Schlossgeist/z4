const std = @import("std");
const api = @import("../api.zig");

const Package =     api.Package;
const Toolchain =   api.Toolchain;

pub const Program = struct {
    package: *Package,
    name: []const u8,

    artifact: std.Build.LazyPath,
    objects: []std.Build.LazyPath,

    pub fn installObject(self: *const Program) void {
        const b = self.package.system.b;
        const system = self.package.system;

        const install_object = b.addInstallFile(
            self.objects[0],
            b.fmt("{s}/main.o", .{ system.install_dir }),
        );

        b.getInstallStep().dependOn(&install_object.step);
    }

    pub fn install(self: *const Program) void {
        const b = self.package.system.b;
        const system = self.package.system;

        const install_file = b.addInstallFile(
            self.artifact,
            b.fmt("{s}/{s}", .{ system.install_dir, self.name }),
        );

        b.getInstallStep().dependOn(&install_file.step);
    }

    pub const Options = struct {
        name: []const u8,
        sources: []const []const u8,
        language: Language,
        libraries: []const []const u8 = &.{},

        pub const Language = enum {
            ada,
            c,
            cpp,
            rust,
            zig,
        };
    };
};

pub const BuildOptions = struct {
    toolchain: *const Toolchain,
    pkg: *Package,
    name: []const u8,
};

fn addLanguageFlags(
    compile: *std.Build.Step.Run,
    language: Program.Options.Language,
) void {
    switch (language) {
        .c => {
            compile.addArgs(&.{
                "-std=gnu11",
                "-Wbad-function-cast",
                "-Wstrict-prototypes",
                "-Wmissing-prototypes",
            });
        },

        .cpp => {
            compile.addArgs(&.{
                "-Wmissing-declarations",
                "-Wno-noexcept-type",
                "-Wno-psabi",
                "-Wno-unused-private-field",
                "-Wno-c99-designator",
                "-D_GLIBCXX_SYSHDR",
                "-fuse-cxa-atexit",
            });
        },
        else => {},
    }
}

pub fn compileSourceFile(
    build_options: BuildOptions,
    file_name: []const u8,
    language: Program.Options.Language,
) std.Build.LazyPath {
    const b = build_options.pkg.system.b;

    const compile = b.addSystemCommand(&.{
        build_options.toolchain.cc,
    });

    const source_dir = std.fs.path.dirname(file_name);
    const basename = std.fs.path.basename(file_name);
    const stem = std.fs.path.stem(basename);

    if (source_dir) |path| {
        compile.setCwd(build_options.toolchain.l4_build.compileDir(build_options.pkg, path));
    }

    compile.addArgs(&.{
        "--target=aarch64-none-elf",

        "-c",
        "-U_GNU_SOURCE",

        "-DL4BID_RELEASE_MODE",
        "-DNDEBUG",

        "-DSYSTEM_arm64_armv8r_std_l4f",
        "-DARCH_arm64",
        "-DCPUTYPE_armv8r",
        "-DL4API_l4f",

        "-D_POSIX_C_SOURCE=200809L",
        "-D_XOPEN_SOURCE=700",
        "-D_FILE_OFFSET_BITS=64",

        "-march=armv8-r",
    });

    addLanguageFlags(compile, language);

    // L4Re generated headers.
    compile.addArg("-I");
    compile.addDirectoryArg(
        build_options.toolchain.l4_build.build_root.path(b, "include/contrib/libstdc++-v3"),
    );

    compile.addArg("-I");
    compile.addDirectoryArg(
        build_options.toolchain.l4_build.build_root.path(b, "include/arm64"),
    );

    compile.addArg("-I");
    compile.addDirectoryArg(
        build_options.toolchain.l4_build.build_root.path(b, "include"),
    );

    compile.addArg("-I");
    compile.addDirectoryArg(
        build_options.toolchain.l4_build.build_root.path(b, "include/contrib/libstdc++-v3"),
    );

    compile.addArg("-nostdinc");

    compile.addArg("-I");
    compile.addDirectoryArg(
        build_options.toolchain.l4_build.build_root.path(b, "include/uclibc-ng"),
    );

    compile.addArg("-isystem");
    compile.addArg(build_options.toolchain.clang_resource_dir);

    compile.addArgs(&.{
        "-include",
        "l4/bid_config.h",

        "-U__linux",
        "-U__gnu_linux__",
        "-Ulinux",
        "-U__linux__",

        "-D__l4re__",

        "-fno-omit-frame-pointer",
        "-funwind-tables",

        "-g",
        "-O2",

        "-fno-strict-aliasing",

        "-Wextra",
        "-Wdouble-promotion",
        "-Wfloat-conversion",
        "-Wfloat-equal",
        "-Wall",

        "-Wmissing-declarations",

        "-fno-common",

        "-mno-outline-atomics",

        "-fstack-protector",

        "-ffunction-sections",
        "-fdata-sections",

        "-fPIE",
    });

    compile.addFileArg(build_options.pkg.root.path(file_name));
    compile.addArg("-o");
    return compile.addOutputFileArg(
        b.fmt("{s}.o", .{ stem }),
    );
}

pub fn linkProgram(
    build_options: BuildOptions,
    objects: []std.Build.LazyPath,
    libraries: []const []const u8,
) Program {
    const b = build_options.pkg.system.b;

    const link = b.addSystemCommand(&.{build_options.toolchain.ld});

    link.addArgs(&.{
        "-m",
        "aarch64elf",
        "--oformat",
        "elf64-littleaarch64",

        "-o",
    });

    const output = link.addOutputFileArg(build_options.name);

    link.addArgs(&.{
        "-nostdlib",
        "--eh-frame-hdr",
        "-static",
        "-pie",
        "--no-dynamic-linker",
        "-z",
        "text",
        "--warn-common",

        "-z",
        "max-page-size=0x1000",
        "-z",
        "common-page-size=0x1000",
        "-z",
        "noexecstack",

        "-Map",
        b.fmt("{s}.map", .{ build_options.name }),

        "-gc-sections",
        "--eh-frame-hdr",
    });

    link.addArg("-L");
    link.addDirectoryArg(build_options.toolchain.l4_build.libL4f());

    link.addArg("-L");
    link.addDirectoryArg(build_options.toolchain.l4_build.libPlain());

    link.addArg("-L");
    link.addDirectoryArg(build_options.toolchain.l4_build.libStd());

    link.addArg("-dT");
    link.addFileArg(build_options.toolchain.l4_build.linkerScript());

    link.addFileArg(build_options.toolchain.l4_build.startup("crt1.p.o"));
    link.addFileArg(build_options.toolchain.l4_build.startup("crti.o"));
    link.addFileArg(build_options.toolchain.l4_build.startup("crtbegin.o"));

    for (objects) |object| {
        link.addFileArg(object);
    }

    for (libraries) |library| {
        const lib_arg = std.fmt.allocPrint(b.allocator, "-l{s}", .{ library }) catch unreachable;
        defer b.allocator.free(lib_arg);

        link.addArg(lib_arg);
    }

    link.addArgs(&.{
        "-lsupc++",
        "-lpthread",
        "-lc",

        "--start-group",
        "-lsupc++",
        "-lc",
        "-lclang_rt-builtins",
        "-lunwind_llvm",
        "--end-group",
    });

    link.addFileArg(build_options.toolchain.l4_build.startup("crtend.o"));
    link.addFileArg(build_options.toolchain.l4_build.startup("crtn.o"));

    return .{
        .package = build_options.pkg,
        .name = build_options.name,
        .artifact = output,
        .objects = objects,
    };
}
