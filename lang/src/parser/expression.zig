pub const Expression = union(enum) {
    literal: Literal,
    binary_op: .{ *Expression, BinaryOp, *Expression },
    unary_op: .{ *Expression, UnaryOp },
};

pub const Literal = union(enum) {
    number: f32,
    string: []const u8,
    boolean: bool,
};

pub const BinaryOp = enum { add, sub, mul, div };
pub const UnaryOp = enum { not, neg };
