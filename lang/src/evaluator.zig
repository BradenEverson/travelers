const Expression = @import("./parser/expression.zig").Expression;
const std = @import("std");
const Literal = @import("./parser/expression.zig").Literal;
const Direction = @import("./parser/expression.zig").Direction;

pub const RuntimeError = error{
    WrongLiteralType,
};

pub const EvaluatorError = RuntimeError;

pub const EvaluatorVtable = struct {
    move_fn: *const fn (Direction, usize) void,
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
                const mag = if (moveinfo.@"1") |magnitude|
                    try (try self.eval(magnitude)).numeric()
                else
                    1.0;
                self.vtable.move_fn(moveinfo.@"0", @intFromFloat(mag));
                return .void;
            },

            .literal => |literal| return literal,

            .binary_op => |bin| {
                const left = try self.eval(bin.@"0");
                const right = try self.eval(bin.@"2");

                return bin.@"1".eval(left, right);
            },

            .block => |statements| {
                var final: Literal = .void;
                for (statements) |statement| {
                    final = try self.eval(statement);
                }

                return final;
            },

            .if_statement => |if_stmt| {
                var final: Literal = .void;

                const result = try self.eval(if_stmt.check);
                const truthy = try result.truthy();
                if (truthy) {
                    final = try self.eval(if_stmt.true_branch);
                } else if (if_stmt.else_branch) |el| {
                    final = try self.eval(el);
                }

                return final;
            },

            else => @panic("Unimplemented expression"),
        }
    }
};
