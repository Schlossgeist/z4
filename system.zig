const std = @import("std");
const api = @import("api.zig");

const Package =     api.Package;
const Toolchain =   api.Toolchain;

const Program =         api.Program;
const ProgramOptions =  api.ProgramOptions;

pub const Target = struct {
    arch: Arch,
    cpu: Cpu,
    abi: Abi,
    platform: Platform,

    pub const Arch = enum {
        amd64,
        arm64,
    };

    pub const Cpu = enum {
        armv8r,
    };

    pub const Abi = enum {
        l4f,
    };

    pub const Platform = enum {
        qemu,
        fvp,
    };
};

pub const System = struct {
    b: *std.Build,
    allocator: std.mem.Allocator,
    target: Target,
    toolchain: Toolchain,
    install_dir: []const u8,

    pub const Options = struct {
        target: Target,
        toolchain: Toolchain.Options,
        install_dir: []const u8 = "bin",
    };

    pub fn init(
        b: *std.Build,
        options: Options,
    ) System {
        return .{
            .b = b,
            .allocator = b.allocator,
            .target = options.target,
            .toolchain = Toolchain.init(b, options.toolchain),
            .install_dir = options.install_dir,
        };
    }

    pub fn resolve_target(
        self: *System,
    ) std.Build.ResolvedTarget {
        return self.b.resolveTargetQuery(
            switch (self.target.arch) {
                .amd64 => .{
                    .cpu_arch = .x86_64,
                    .os_tag = .freestanding,
                },
                .arm64 => .{
                    .cpu_arch = .aarch64,
                    .os_tag = .freestanding,
                },
            }
        );
    }

    pub fn package(
        self: *System,
        options: Package.Options,
    ) *Package {
        const pkg: *Package = self.allocator.create(Package) catch unreachable;
        pkg.* = Package.init(self, options);
        pkg.evaluatePackageDescription(options.desc);

        return pkg;
    }
};
