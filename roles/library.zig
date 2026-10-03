const std = @import("std");
const api = @import("../api.zig");

const Package = api.Package;

pub const Library = struct {
    package: *Package,
    name: []const u8,
};
