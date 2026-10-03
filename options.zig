const std = @import("std");

pub const Type = enum {
    string,
    number,
    flag,
};

pub fn Options(comptime schema: anytype) type {
    const fields = @typeInfo(@TypeOf(schema)).@"struct".fields;

    var names: [fields.len][]const u8 = undefined;
    var types: [fields.len]type = undefined;

    inline for (fields, 0..) |field, i| {
        const option = @field(schema, field.name);

        names[i] = field.name;
        types[i] = enumToType(option.type);
    }

    return @Struct(.auto, null, &names, &types, &@splat(.{}));
}

pub fn parse(
    b: *std.Build,
    comptime schema: anytype,
) Options(schema) {
    var result: Options(schema) = undefined;

    inline for (@typeInfo(@TypeOf(schema)).@"struct".fields) |field| {
        const option = @field(schema, field.name);

        @field(result, field.name) = switch (option.type) {
            .flag => b.option(
                bool,
                field.name,
                option.description,
            ) orelse defaultValue(option),
            .number => b.option(
                comptime_int,
                field.name,
                option.description,
            ) orelse defaultValue(option),
            .string => b.option(
                []const u8,
                field.name,
                option.description,
            ) orelse defaultValue(option),
            else => @compileError("Unknown option type")
        };
    }

    return result;
}

fn enumToType(comptime kind: Type) type {
    return switch (kind) {
        .flag => bool,
        .number => comptime_int,
        .string => []const u8,
    };
}

fn defaultValue(comptime option: anytype) enumToType(option.type) {
    if (@hasField(@TypeOf(option), "default")) {
        return option.default;
    }

    return switch (option.type) {
        .flag => false,
        .number => 0,
        .string => "",
        else => @compileError("Unknown option type")
    };
}
