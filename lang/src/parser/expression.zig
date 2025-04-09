pub const Expression = union(enum) {
    literal: Literal,
    binary_op: struct { *const Expression, BinaryOp, *const Expression },
    unary_op: struct { *const Expression, UnaryOp },
};

pub const Literal = union(enum) {
    number: f32,
    string: []const u8,
    boolean: bool,
};

pub const BinaryOp = enum { add, sub, mul, div, equal, not_equal, gt, gte, lt, lte };
pub const UnaryOp = enum { not, neg };
