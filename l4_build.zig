const std = @import("std");
const api = @import("api.zig");

const Package = api.Package;
const Target =  api.Target;

pub const L4Build = struct {
    b: *std.Build,
    source_root: std.Build.LazyPath,
    build_root: std.Build.LazyPath,

    pub fn init(
        b: *std.Build,
        source_root: std.Build.LazyPath,
        build_root: std.Build.LazyPath,
    ) L4Build {
        return .{
            .b = b,
            .source_root = source_root,
            .build_root = build_root, 
        };
    }

    pub fn compileDir(
        self: *const L4Build,
        package: *const Package,
        source_subdir: []const u8,
    ) std.Build.LazyPath {
        const b = package.system.b;
        const target = package.system.target;

        return self.build_root.path(b, b.fmt(
            "pkg/{s}/{s}/OBJ-{s}-{s}-{s}", .{
                package.name,
                source_subdir,
                systemName(target),
                variant(),
                abiName(target),
            },
        ));
    }

    pub fn libL4f(self: *const L4Build) std.Build.LazyPath {
        return self.build_root.path(self.b, "lib/arm64_armv8r/std/l4f");
    }

    pub fn libPlain(self: *const L4Build) std.Build.LazyPath {
        return self.build_root.path(self.b, "lib/arm64_armv8r/std/plain");
    }

    pub fn libStd(self: *const L4Build) std.Build.LazyPath {
        return self.build_root.path(self.b, "lib/std");
    }

    pub fn linkerScript(
        self: *const L4Build,
    ) std.Build.LazyPath {
        return self.libPlain().path(self.b, "main_pie.ld");
    }

    pub fn startup(
        self: *const L4Build,
        name: []const u8,
    ) std.Build.LazyPath {
        return self.libPlain().path(self.b, name);
    }
};

fn systemName(target: Target) []const u8 {
    return switch (target.arch) {
        .arm64 => switch (target.cpu) {
            .armv8r =>      "arm64_armv8r",
        },
        .amd64 =>           "amd64",
    };
}

fn variant() []const u8 {
    return "std";
}

fn abiName(target: Target) []const u8 {
    return switch (target.abi) {
        .l4f => "l4f",
    };
}
