const std = @import("std");
const RuntimeError = @import("../evaluator.zig").RuntimeError;
const Keyword = @import("../tokenizer.zig").Keyword;

pub const Direction = enum {
    left,
    right,
    up,
    down,
};

pub const IfStatement = struct {
    check: *const Expression,
    true_branch: *const Expression,
    else_branch: ?*const Expression,
};

pub const Assignment = struct {
    name: []const u8,
    eval_to: *const Expression,
};

pub const WhileLoop = struct {
    cond: *const Expression,
    do: *const Expression,
};

pub const Expression = union(enum) {
    move: struct { Direction, ?*const Expression },

    block: []*const Expression,

    if_statement: IfStatement,

    grouping: *const Expression,

    literal: Literal,

    variable: []const u8,
    assignment: Assignment,

    while_loop: WhileLoop,

    binary_op: struct { *const Expression, BinaryOp, *const Expression },
    unary_op: struct { *const Expression, UnaryOp },

    pub fn format(
        self: *const Expression,
        _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self.*) {
            .assignment => |a| {
                try writer.print("let {s} = {};", .{ a.name, a.eval_to });
            },
            .variable => |v| {
                try writer.print("{s}", .{v});
            },

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

            .block => |statements| {
                try writer.print("{{\n", .{});

                for (statements) |statement| {
                    try writer.print("\t{}\n", .{statement});
                }

                try writer.print("}}", .{});
            },

            .if_statement => |is| {
                try writer.print("if ({}) {}\n", .{ is.check, is.true_branch });
                if (is.else_branch) |el| {
                    try writer.print("else {}", .{el});
                }
            },

            .while_loop => |wl| {
                try writer.print("while ({}) {}\n", .{ wl.cond, wl.do });
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

    pub fn eql(self: *const Literal, other: Literal) bool {
        // Might become more complex in the future if we encorporate strings, that's why it's its own fn
        return std.meta.eql(self.*, other);
    }

    pub fn truthy(self: *const Literal) RuntimeError!bool {
        return switch (self.*) {
            .number => |n| n != 0,
            .boolean => |b| b,
            else => error.WrongLiteralType,
        };
    }

    pub fn numeric(self: *const Literal) RuntimeError!f32 {
        return switch (self.*) {
            .number => |n| n,
            else => error.WrongLiteralType,
        };
    }

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
    and_op,
    or_op,

    pub fn eval(self: *const BinaryOp, left: Literal, right: Literal) RuntimeError!Literal {
        return switch (self.*) {
            .add => {
                const l = try left.numeric();
                const r = try right.numeric();

                return .{ .number = l + r };
            },

            .sub => {
                const l = try left.numeric();
                const r = try right.numeric();

                return .{ .number = l - r };
            },

            .mul => {
                const l = try left.numeric();
                const r = try right.numeric();

                return .{ .number = l * r };
            },

            .div => {
                const l = try left.numeric();
                const r = try right.numeric();

                return .{ .number = l / r };
            },

            .and_op => {
                const l = try left.truthy();
                const r = try right.truthy();

                return .{ .boolean = l and r };
            },

            .or_op => {
                const l = try left.truthy();
                const r = try right.truthy();

                return .{ .boolean = l or r };
            },

            .equal => return .{ .boolean = left.eql(right) },
            .not_equal => return .{ .boolean = !left.eql(right) },

            .gt => {
                const l = try left.numeric();
                const r = try right.numeric();

                return .{ .boolean = l > r };
            },

            .lt => {
                const l = try left.numeric();
                const r = try right.numeric();

                return .{ .boolean = l < r };
            },

            .gte => {
                const l = try left.numeric();
                const r = try right.numeric();

                return .{ .boolean = l >= r };
            },

            .lte => {
                const l = try left.numeric();
                const r = try right.numeric();

                return .{ .boolean = l <= r };
            },
        };
    }

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

            .and_op => try writer.print("and", .{}),
            .or_op => try writer.print("or", .{}),
        }
    }
};
pub const UnaryOp = enum {
    not,
    neg,

    pub fn eval(self: *const UnaryOp, val: Literal) RuntimeError!Literal {
        switch (self.*) {
            .not => {
                const b = try val.truthy();
                return .{ .boolean = !b };
            },
            .neg => {
                const n = try val.numeric();
                return .{ .number = -n };
            },
        }
    }

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
