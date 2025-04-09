const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const expression = @import("./parser/expression.zig");
const Expression = expression.Expression;
const BinaryOp = expression.BinaryOp;
const UnaryOp = expression.UnaryOp;

const Token = tokenizer.Token;
const TokenTag = tokenizer.TokenTag;

pub const ParseError = error{ExpectedTokenFound};

pub const ParserError = ParseError || std.mem.Allocator.Error;

pub const Parser = struct {
    stream: []const Token,
    index: usize = 0,
    arena: std.heap.ArenaAllocator,

    pub fn init(stream: []const Token, child_allocator: std.mem.Allocator) Parser {
        return Parser{
            .stream = stream,
            .arena = std.heap.ArenaAllocator.init(child_allocator),
        };
    }

    fn allocator(self: *Parser) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn deinit(self: *Parser) void {
        self.arena.deinit();
    }

    fn peek(self: *Parser) TokenTag {
        return self.stream[self.index].tag;
    }

    fn advance(self: *Parser) void {
        if (self.index >= self.stream.len - 1) {
            self.index = self.stream.len - 1;
        } else {
            self.index += 1;
        }
    }

    fn consume(self: *Parser, tok: TokenTag) ParserError!void {
        if (std.meta.eql(self.peek(), tok)) {
            self.advance();
            return;
        } else {
            return ParserError.ExpectedTokenFound;
        }
    }

    fn at_end(self: *Parser) bool {
        return self.peek() == .eof;
    }

    pub fn parse(self: *Parser, statements: *std.ArrayList(*Expression)) ParserError!void {
        while (!self.at_end()) : (self.advance()) {
            const s = try self.statement();
            try statements.append(s);
        }
    }

    fn statement(self: *Parser) ParserError!*Expression {
        const tag = self.peek();
        switch (tag) {
            .keyword => |key| switch (key) {
                .up, .down, .left, .right => @panic("Move action"),
            },
            else => {},
        }

        const e = try self.expression();
        try self.consume(.semicolon);
        return e;
    }

    fn expression(self: *Parser) ParserError!*Expression {
        return switch (self.peek()) {
            else => try self.equality(),
        };
    }

    fn equality(self: *Parser) ParserError!*Expression {
        var expr = try self.comparison();

        grow: switch (self.peek()) {
            .equalequal, .bangequal => {
                const op: BinaryOp = switch (self.peek()) {
                    .equalequal => .equal,
                    .bangequal => .not_equal,
                    else => unreachable,
                };
                self.advance();

                const right = try self.comparison();

                const new_expr = try self.allocator().create(Expression);
                new_expr.* = .{
                    .binary_op = .{
                        expr,
                        op,
                        right,
                    },
                };
                expr = new_expr;
                continue :grow self.peek();
            },
            else => {},
        }

        return expr;
    }

    fn comparison(self: *Parser) ParserError!*Expression {
        var expr = try self.term();

        grow: switch (self.peek()) {
            .gt, .gte, .lt, .lte => {
                const op: BinaryOp = switch (self.peek()) {
                    .gt => .gt,
                    .lt => .lt,
                    .gte => .gte,
                    .lte => .lte,

                    else => unreachable,
                };
                self.advance();

                const right = try self.term();

                const new_expr = try self.allocator().create(Expression);
                new_expr.* = .{
                    .binary_op = .{
                        expr,
                        op,
                        right,
                    },
                };
                expr = new_expr;
                continue :grow self.peek();
            },
            else => {},
        }

        return expr;
    }

    fn term(self: *Parser) ParserError!*Expression {
        var expr = try self.factor();

        grow: switch (self.peek()) {
            .plus, .minus => {
                const op: BinaryOp = switch (self.peek()) {
                    .plus => .add,
                    .minus => .sub,

                    else => unreachable,
                };
                self.advance();

                const right = try self.factor();

                const new_expr = try self.allocator().create(Expression);
                new_expr.* = .{
                    .binary_op = .{
                        expr,
                        op,
                        right,
                    },
                };
                expr = new_expr;
                continue :grow self.peek();
            },
            else => {},
        }

        return expr;
    }

    fn factor(self: *Parser) ParserError!*Expression {
        var expr = try self.unary();

        grow: switch (self.peek()) {
            .star, .slash => {
                const op: BinaryOp = switch (self.peek()) {
                    .star => .mul,
                    .slash => .div,

                    else => unreachable,
                };
                self.advance();

                const right = try self.unary();

                const new_expr = try self.allocator().create(Expression);
                new_expr.* = .{
                    .binary_op = .{
                        expr,
                        op,
                        right,
                    },
                };
                expr = new_expr;
                continue :grow self.peek();
            },
            else => {},
        }

        return expr;
    }

    fn unary(self: *Parser) ParserError!*Expression {
        switch (self.peek()) {
            .bang, .minus => {
                const op: UnaryOp = switch (self.peek()) {
                    .bang => .not,
                    .minus => .neg,
                    else => unreachable,
                };
                self.advance();

                const un = try self.unary();

                const new_expr = try self.allocator().create(Expression);
                new_expr.* = .{
                    .unary_op = .{ un, op },
                };

                return new_expr;
            },
            else => return self.primary(),
        }
    }

    fn primary(self: *Parser) ParserError!*Expression {
        const prim = val: switch (self.peek()) {
            .number => |n| {
                const num = try self.allocator().create(Expression);
                num.* = .{ .literal = .{ .number = n } };

                break :val num;
            },
            else => error.ExpectedTokenFound,
        };

        self.advance();
        return prim;
    }
};
