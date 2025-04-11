const Expression = @import("./parser/expression.zig").Expression;

pub const Evaluator = struct {
    pub fn eval(self: *Evaluator, ast: Expression) void {
        _ = self;
        _ = ast;
    }
};
