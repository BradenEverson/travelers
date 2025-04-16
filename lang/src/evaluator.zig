const Expression = @import("./parser/expression.zig").Expression;
const std = @import("std");
const Literal = @import("./parser/expression.zig").Literal;
const Direction = @import("./parser/expression.zig").Direction;
const OwnedScope = @import("./evaluator/scope.zig").OwnedScope;

pub const RuntimeError = error{
    WrongLiteralType,
    UninitializedVariable,
};

pub const EvaluatorError = RuntimeError || std.mem.Allocator.Error;

pub const EvaluatorVtable = struct {
    move_fn: *const fn (Direction, usize) void,
    print_fn: ?*const fn (Literal) void,
};

pub const Evaluator = struct {
    allocator: std.mem.Allocator,
    scope: OwnedScope,
    vtable: EvaluatorVtable,

    pub fn init(allocator: std.mem.Allocator, vtable: EvaluatorVtable) Evaluator {
        return Evaluator{
            .allocator = allocator,
            .scope = OwnedScope.init(allocator),
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

            .unary_op => |un| {
                const val = try self.eval(un.@"0");

                return un.@"1".eval(val);
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

            .grouping => |inner| {
                return self.eval(inner);
            },

            .assignment => |assign| {
                const assigned = try self.eval(assign.eval_to);
                try self.scope.register(assign.name, assigned);

                return .void;
            },

            .variable => |name| {
                if (self.scope.get(name)) |val| {
                    return val;
                } else {
                    return error.UninitializedVariable;
                }
            },
        }
    }
};
