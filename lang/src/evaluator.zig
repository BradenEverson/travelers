const Expression = @import("./parser/expression.zig").Expression;
const std = @import("std");
const Literal = @import("./parser/expression.zig").Literal;

pub const RuntimeError = error{
    WrongLiteralType,
};

pub const EvaluatorError = RuntimeError;

pub const Direction = enum {
    left,
    right,
    up,
    down,
};

pub const EvaluatorVtable = struct {
    move_fn: *const fn (Direction, i32) void,
    print_fn: ?*const fn (Literal) void,
};

pub const Evaluator = struct {
    allocator: std.mem.Allocator,
    scope: std.AutoHashMap([]const u8, Literal),
    vtable: EvaluatorVtable,

    pub fn init(allocator: std.mem.Allocator, vtable: EvaluatorVtable) Evaluator {
        return Evaluator{
            .allocator = allocator,
            .scope = std.AutoHashMap([]const u8, Literal).init(allocator),
            .vtable = vtable,
        };
    }

    pub fn eval(self: *Evaluator, ast: *const Expression) EvaluatorError!Literal {
        switch (ast.*) {
            .move_left => |times| {
                if (times) |expr| {
                    _ = expr;
                    @panic("Implement expression running for how many moves");
                } else {
                    self.vtable.move_fn(.left, 1);
                    return .void;
                }
            },

            .move_right => |times| {
                if (times) |expr| {
                    _ = expr;
                    @panic("Implement expression running for how many moves");
                } else {
                    self.vtable.move_fn(.right, 1);
                    return .void;
                }
            },

            else => @panic("Unimplemented expression"),
        }
    }
};
