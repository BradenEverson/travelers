const Expression = @import("./parser/expression.zig").Expression;
const std = @import("std");
const Literal = @import("./parser/expression.zig").Literal;
const Direction = @import("./parser/expression.zig").Direction;
const OwnedScope = @import("./evaluator/scope.zig").OwnedScope;
const TileType = @import("game_std.zig").TileType;

pub const RuntimeError = error{
    WrongLiteralType,
    UninitializedVariable,
};

pub const EvaluatorError = RuntimeError || std.mem.Allocator.Error;

pub const EvaluatorVtable = struct {
    move_fn: *const fn (Direction, usize) void,
    print_fn: ?*const fn (Literal) void,
    block_fn: ?*const fn ([]*const Expression) void,
    while_fn: *const fn (*const Expression) void,
    peek_fn: *const fn (Direction) TileType,
};

pub const Evaluator = struct {
    allocator: std.mem.Allocator,
    scope: OwnedScope,
    vtable: EvaluatorVtable,

    pub fn reset(self: *Evaluator) void {
        self.scope.reset();
    }

    pub fn init(allocator: std.mem.Allocator, vtable: EvaluatorVtable) Evaluator {
        return Evaluator{
            .allocator = allocator,
            .scope = OwnedScope.init(allocator),
            .vtable = vtable,
        };
    }

    pub fn eval(self: *Evaluator, ast: *const Expression) EvaluatorError!Literal {
        switch (ast.*) {
            .peek => |direction| {
                const tt = self.vtable.peek_fn(direction);
                return .{ .tile = tt };
            },

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
                if (self.vtable.block_fn) |bf| {
                    bf(statements);
                    return .void;
                } else {
                    var final: Literal = .void;
                    for (statements) |statement| {
                        final = try self.eval(statement);
                    }

                    return final;
                }
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

            .while_loop => |wl| {
                const cond = try self.eval(wl.cond);
                if (try cond.truthy()) {
                    self.vtable.while_fn(wl.do);
                }

                return .void;
            },
        }
    }
};
