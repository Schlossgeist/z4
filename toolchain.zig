const std = @import("std");
const api = @import("api.zig");

const Package = api.Package;

const Program =         api.Program;

const BuildOptions =        api.BuildOptions;
const compileSourceFile =   api.compileSourceFile;
const linkProgram =         api.linkProgram;

const L4Build = @import("l4_build.zig").L4Build;

pub const Toolchain = struct {
    kind: Kind,
    l4_build: L4Build,
    cc: []const u8,
    cxx: []const u8,
    ld: []const u8,
    clang_resource_dir: []const u8,

    pub const Kind = enum {
        gcc,
        clang,
    };

    pub const Options = struct {
        kind: Kind = .clang,
        source_dir: std.Build.LazyPath,
        build_dir: std.Build.LazyPath,

        cc: []const u8 = "clang-19",
        cxx: []const u8 = "clang++-19",
        ld: []const u8 = "aarch64-none-elf-ld",
        clang_resource_dir: []const u8 = "/usr/lib64/clang/19/include",
    };

    pub fn init(b: *std.Build, options: Options) Toolchain {
        return .{
            .kind = options.kind,
            .l4_build = L4Build.init(b, options.source_dir, options.build_dir),
            .cc = options.cc,
            .cxx = options.cxx,
            .ld = options.ld,
            .clang_resource_dir = options.clang_resource_dir,
        };
    }

    pub fn compiler(
        self: *const Toolchain,
        language: Program.Options.Language
    ) []const u8 {
        return switch (language) {
            .c => self.cc,
            .cpp => self.cxx,
            _ => unreachable,
        };
    }

    pub fn configureProgram(
        self: *const Toolchain,
        pkg: *Package,
        name: []const u8,
        program_options: Program.Options,
    ) Program {
        const build_options: BuildOptions = .{ .toolchain = self, .pkg = pkg, .name = name };
        const alloc = pkg.system.b.allocator;

        var objects: std.ArrayList(std.Build.LazyPath) = .empty;
        for (program_options.sources) |source| {
            objects.append(alloc,
                compileSourceFile(
                    build_options,
                    source,
                    program_options.language
                ),
            ) catch unreachable;
        }

        return linkProgram(
            build_options,
            objects.items,
            program_options.libraries
        );
    }
};
