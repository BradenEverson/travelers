const std = @import("std");
const Keyword = @import("../tokenizer.zig").Keyword;

pub const Direction = enum {
    left,
    right,
    up,
    down,
};

pub const Expression = union(enum) {
    move: struct { Direction, ?*const Expression },

    grouping: *const Expression,

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
            .grouping => |inner| {
                try writer.print("({})", .{inner});
            },

            .literal => |lit| {
                try writer.print("{}", .{lit});
            },

            .binary_op => |bin| {
                try writer.print("{} {} {}", .{ bin.@"0", bin.@"1", bin.@"2" });
            },

            .unary_op => |un| {
                try writer.print("{}{}", .{ un.@"1", un.@"0" });
            },

            .move => |e| {
                if (e.@"1") |ex| {
                    try writer.print("move {} {}", .{ e.@"0", ex });
                } else {
                    try writer.print("move {}", .{e.@"0"});
                }
            },
        }
    }
};

pub fn direction_from_keyword(key: Keyword) ?Direction {
    return switch (key) {
        .up => .up,
        .down => .down,
        .left => .left,
        .right => .right,
        else => null,
    };
}

pub const Literal = union(enum) {
    number: f32,
    boolean: bool,
    void,

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

            .void => {
                try writer.print("void", .{});
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
pub const UnaryOp = enum {
    not,
    neg,

    pub fn format(
        self: *const UnaryOp,
        _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            .not => try writer.print("!", .{}),
            .neg => try writer.print("-", .{}),
        }
    }
};
