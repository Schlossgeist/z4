//! public API of the Z4 Build System

pub const Package =             @import("package.zig").Package;
pub const PackageDescription =  @import("package.zig").PackageDescription;

pub const System =      @import("system.zig").System;
pub const Target =      @import("system.zig").Target;
pub const Toolchain =   @import("toolchain.zig").Toolchain;

pub const Program =             @import("roles/program.zig").Program;
pub const BuildOptions =        @import("roles/program.zig").BuildOptions;
pub const compileSourceFile =   @import("roles/program.zig").compileSourceFile;
pub const linkProgram =         @import("roles/program.zig").linkProgram;

pub const Library = @import("roles/library.zig").Library;
pub const Test =    @import("roles/test.zig").Test;

pub const CommandLineOptions =  @import("options.zig").Options;
pub const parseOptions = @import("options.zig").parse;
pub const optionsSchema = @import("options.zon");
