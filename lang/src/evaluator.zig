const Expression = @import("./parser/expression.zig").Expression;
const std = @import("std");
const Literal = @import("./parser/expression.zig").Literal;
const Direction = @import("./parser/expression.zig").Direction;

pub const RuntimeError = error{
    WrongLiteralType,
};

pub const EvaluatorError = RuntimeError;

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
            .move => |moveinfo| {
                self.vtable.move_fn(moveinfo.@"0", 1);
                return .void;
            },

            else => @panic("Unimplemented expression"),
        }
    }
};
