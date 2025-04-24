const std = @import("std");

pub const TileType = enum {
    open,
    enemy,
    stone,
    wood,
    border,

    pub fn from_int(from: i32) ?TileType {
        return switch (from) {
            0 => .open,
            1 => .enemy,
            2 => .stone,
            3 => .wood,
            else => null,
        };
    }

    pub fn format(
        self: *const TileType,
        _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            .open => try writer.print("open", .{}),
            .enemy => try writer.print("enemy", .{}),
            .stone => try writer.print("stone", .{}),
            .wood => try writer.print("wood", .{}),
            .border => try writer.print("border", .{}),
        }
    }
};

pub const Unit = struct {
    health: u8,
    material: u8,

    /// A default player starts with 100 health and 3 materials to place down
    pub fn default() Unit {
        return .{
            .health = 100,
            .material = 3,
        };
    }
};
