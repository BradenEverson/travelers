const Expression = @import("./parser/expression.zig").Expression;
const std = @import("std");
const Literal = @import("./parser/expression.zig").Literal;

pub const Evaluator = struct {
    allocator: std.mem.Allocator,
    scope: std.AutoHashMap([]const u8, Literal),

    pub fn init(allocator: std.mem.Allocator) Evaluator {
        return Evaluator{
            .allocator = allocator,
            .scope = std.AutoHashMap([]const u8, Literal).init(allocator),
        };
    }

    pub fn eval(self: *Evaluator, ast: Expression) void {
        _ = self;
        _ = ast;
    }
};
