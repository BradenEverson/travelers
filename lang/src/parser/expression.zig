const std = @import("std");

pub const Expression = union(enum) {
    move_left: ?*const Expression,
    move_right: ?*const Expression,
    move_up: ?*const Expression,
    move_down: ?*const Expression,

    literal: Literal,
    binary_op: struct { *const Expression, BinaryOp, *const Expression },
    unary_op: struct { *const Expression, UnaryOp },

    pub fn format(
        self: *const Expression,
        _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            .literal => |lit| {
                try writer.print("{}", .{lit});
            },

            .binary_op => |bin| {
                try writer.print("{} {} {}", .{ bin.@"0", bin.@"1", bin.@"2" });
            },
            else => try writer.print("not done yet", .{}),
        }
    }
};

pub const Literal = union(enum) {
    number: f32,
    boolean: bool,

    pub fn format(
        self: *const Literal,
        _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            .number => |n| {
                try writer.print("{d}", .{n});
            },

            .boolean => |b| {
                try writer.print("{}", .{b});
            },
        }
    }
};

pub const BinaryOp = enum {
    add,
    sub,
    mul,
    div,
    equal,
    not_equal,
    gt,
    gte,
    lt,
    lte,

    pub fn format(
        self: *const BinaryOp,
        _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            .add => try writer.print("+", .{}),
            .sub => try writer.print("-", .{}),
            .mul => try writer.print("*", .{}),
            .div => try writer.print("/", .{}),
            .equal => try writer.print("==", .{}),
            .not_equal => try writer.print("!=", .{}),
            .gt => try writer.print(">", .{}),
            .gte => try writer.print(">=", .{}),
            .lt => try writer.print("<", .{}),
            .lte => try writer.print("<=", .{}),
        }
    }
};
pub const UnaryOp = enum { not, neg };
