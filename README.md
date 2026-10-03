# Z4 Build System – alternative build system for L4Re

## Goals
- **Comprehensive Configuration**: Two central files describe the complete
  build process. `build.zig` contains what to build, `build.zig.zon` says
  where to find the source.
- **Extendable**: The programmable nature of the underlying Zig infrastructure
  allows for easy customization and extension.
- **Fast and Incremental**: With the build graph fully expressed as Zig code
  and compiled into a binary, builds are fast and incremental.
- **Minimal Dependencies**: If you can provide a compiler toolchain for the
  target platform and your host can run Zig, you can build L4Re. No Makefiles,
  no Perl, no shell scripts.
- **Reproducible Builds**: The build system is designed to produce the same
  output given the same input, down to the byte and completely independent
  of the build environment.

### build.zig
```zig
const std = @import("std");
const z4 = @import("z4");

pub fn build(b: *std.Build) void {
  const options = z4.api.parseOptions(b, z4.api.optionsSchema);
  var system = z4.api.System.init(b, .{
    .target = .{
      .arch =     .arm64,
      .cpu =      .armv8r,
      .abi =      .l4f,
      .platform = .fvp,
    },
    .toolchain = .{
      .kind =         .clang,
      .source_dir =   b.path(options.l4_source_directory),
      .build_dir =    b.path(options.l4_build_directory),
    },
    .install_dir =      options.install_directory,
  });

  _ = system.package(.{
    .name = "ahci-driver",
    .root = b.dependency("ahci_driver", .{}),
    .desc = @import("ahci_driver").package,
  });

  _ = system.package(.{
    .name = "hello",
    .root = b.dependency("hello", .{}),
    .desc = @import("hello").package,
  });
}
```

### build.zig.zon
```zig
.{
  .name = .l4re,
  .version = "0.1.0",

  .dependencies = .{
    .z4 = .{
      .path = "z4",
    },

    .hello = .{
      .path = "pkg/hello",
    },

    .ahci_driver = .{
      .path = "pkg/ahci-driver",
    },
  },

  .fingerprint = 0x53075448b24cbcac,
  .paths = .{""},
}
```

### pkg/hello/build.zig
```zig
const std = @import("std");
const z4 = @import("z4");

pub const package: z4.api.PackageDescription = .{
  .programs = &.{
    .{
      .name = "hello",
      .sources = &.{
        "server/src/main.c",
      },
      .language = .c,
    },
  },
};

pub fn describe(system: *z4.api.System) void { _ = system; }
pub fn build(b: *std.Build) void { _ = b; }
```

#### TODO
- [X] Build the `hello` example program.
- [ ] Build the `ahci-driver` program.
- [ ] Replace everything under `tool/` with native Zig implementations, including
      `imagebuilder` and `kconfig`.
