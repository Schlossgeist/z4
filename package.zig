const std = @import("std");
const api = @import("api.zig");

const System = api.System;

const Program = api.Program;

const L4Build = @import("l4_build.zig");

pub const PackageDescription = struct {
    programs: []const Program.Options = &.{},
};

pub const Package = struct {
    system: *System,
    name: []const u8,
    root: *std.Build.Dependency,

    programs: std.ArrayList(Program),

    pub const Options = struct {
        name: []const u8,
        root: *std.Build.Dependency,
        desc: PackageDescription,
    };

    pub fn init(
        system: *System,
        options: Options,
    ) Package {
        return .{
            .system = system,
            .name = options.name,
            .root = options.root,
            .programs = .empty,
        };
    }

    pub fn evaluatePackageDescription(
        self: *Package,
        pkg_desc: PackageDescription,
    ) void {
        for (pkg_desc.programs) |program_options| {
            const program = self.system.toolchain.configureProgram(
                self,
                program_options.name,
                program_options,
            );
            self.programs.append(self.system.allocator, program) catch unreachable;
            program.installObject();
            program.install();
        }
    }
};
