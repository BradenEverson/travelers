const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const expression = @import("./parser/expression.zig");
const direction_from_keyword = @import("./parser/expression.zig").direction_from_keyword;
const Expression = expression.Expression;
const BinaryOp = expression.BinaryOp;
const UnaryOp = expression.UnaryOp;

const Token = tokenizer.Token;
const TokenTag = tokenizer.TokenTag;

pub const ParseError = error{ ExpectedTokenFound, UnexpectedKeyword, ExpectedIdentifier };

pub const ParserError = ParseError || std.mem.Allocator.Error;

pub const ParserErrorContext = struct {
    wanted_token: []const u8,
    line: usize,
    col: usize,
    len: usize,
};

pub const Parser = struct {
    stream: ?[]const Token,
    index: usize = 0,
    arena: std.heap.ArenaAllocator,

    err_ctx: ParserErrorContext,

    pub fn init(stream: ?[]const Token, child_allocator: std.mem.Allocator) Parser {
        return Parser{
            .stream = stream,
            .arena = std.heap.ArenaAllocator.init(child_allocator),
            .err_ctx = undefined,
        };
    }

    pub fn set_tokens(self: *Parser, tokens: []const Token) void {
        self.stream = tokens;
    }

    fn allocator(self: *Parser) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn deinit(self: *Parser) void {
        self.arena.deinit();
    }

    fn peek(self: *Parser) ?TokenTag {
        return self.stream.?[self.index].tag;
    }

    fn advance(self: *Parser) void {
        if (self.index >= self.stream.?.len - 1) {
            self.index = self.stream.?.len - 1;
        } else {
            self.index += 1;
        }
    }

    fn consume(self: *Parser, tok: TokenTag) ParserError!void {
        if (std.meta.eql(self.peek().?, tok)) {
            self.advance();
            return;
        } else {
            return ParserError.ExpectedTokenFound;
        }
    }

    fn at_end(self: *Parser) bool {
        return self.peek().? == .eof;
    }

    pub fn parse(self: *Parser, statements: *std.ArrayList(*Expression)) ParserError!void {
        while (!self.at_end()) {
            const s = try self.statement();
            try statements.append(s);
        }
    }

    fn move_statement(self: *Parser, expr: *Expression) ParserError!void {
        self.advance();
        const tag = self.peek().?;
        switch (tag) {
            .keyword => |key| {
                switch (key) {
                    .up, .down, .left, .right => {
                        self.advance();
                        const dir = direction_from_keyword(key) orelse unreachable;
                        expr.* = .{ .move = .{ dir, null } };
                    },
                    else => return error.UnexpectedKeyword,
                }
            },
            else => return error.ExpectedTokenFound,
        }

        if (!std.meta.eql(self.peek().?, .semicolon)) {
            const eval = try self.expression();
            expr.*.move.@"1" = eval;
        }
        return self.consume(.semicolon);
    }

    fn if_statement(self: *Parser, expr: *Expression) ParserError!void {
        try self.consume(.{ .keyword = .if_key });
        try self.consume(.openparen);

        const check = try self.expression();
        try self.consume(.closeparen);
        const exec = try self.block();

        var else_branch: ?*const Expression = null;
        if (std.meta.eql(self.peek().?, .{ .keyword = .else_key })) {
            self.advance();
            else_branch = try self.statement();
        }

        expr.* = .{ .if_statement = .{ .check = check, .true_branch = exec, .else_branch = else_branch } };
    }

    fn assignment_statement(self: *Parser, new_expr: *Expression) !void {
        try self.consume(.{ .keyword = .let });

        switch (self.peek().?) {
            .ident => |i| {
                self.advance();
                try self.consume(.equals);
                const next = try self.expression();

                try self.consume(.semicolon);

                new_expr.* = .{ .assignment = .{ .name = i, .eval_to = next } };
            },
            else => return error.ExpectedIdentifier,
        }
    }

    fn statement(self: *Parser) ParserError!*Expression {
        const tag = self.peek().?;
        switch (tag) {
            .keyword => |key| {
                const new_expr = try self.allocator().create(Expression);
                switch (key) {
                    .let => try self.assignment_statement(new_expr),
                    .move => try self.move_statement(new_expr),
                    .if_key => try self.if_statement(new_expr),
                    else => {
                        const e = try self.expression();
                        try self.consume(.semicolon);
                        return e;
                    },
                }

                return new_expr;
            },
            .openbrace => return self.block(),
            else => {
                const e = try self.expression();
                try self.consume(.semicolon);
                return e;
            },
        }
    }

    fn expression(self: *Parser) ParserError!*Expression {
        return switch (self.peek().?) {
            else => try self.equality(),
        };
    }

    fn block(self: *Parser) ParserError!*Expression {
        try self.consume(.openbrace);
        var items = std.ArrayList(*const Expression).init(self.allocator());

        while (!std.meta.eql(self.peek().?, .closebrace)) {
            const expr = try self.statement();
            try items.append(expr);
        }

        try self.consume(.closebrace);

        const new_expr = try self.allocator().create(Expression);
        new_expr.* = .{ .block = items.items };
        return new_expr;
    }

    fn equality(self: *Parser) ParserError!*Expression {
        var expr = try self.comparison();

        grow: switch (self.peek().?) {
            .equalequal, .bangequal => {
                const op: BinaryOp = switch (self.peek().?) {
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
                continue :grow self.peek().?;
            },
            else => {},
        }

        return expr;
    }

    fn comparison(self: *Parser) ParserError!*Expression {
        var expr = try self.term();

        grow: switch (self.peek().?) {
            .gt, .gte, .lt, .lte => {
                const op: BinaryOp = switch (self.peek().?) {
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
                continue :grow self.peek().?;
            },
            else => {},
        }

        return expr;
    }

    fn term(self: *Parser) ParserError!*Expression {
        var expr = try self.factor();

        grow: switch (self.peek().?) {
            .plus, .minus => {
                const op: BinaryOp = switch (self.peek().?) {
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
                continue :grow self.peek().?;
            },
            else => {},
        }

        return expr;
    }

    fn factor(self: *Parser) ParserError!*Expression {
        var expr = try self.unary();

        grow: switch (self.peek().?) {
            .star, .slash => {
                const op: BinaryOp = switch (self.peek().?) {
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
                continue :grow self.peek().?;
            },
            else => {},
        }

        return expr;
    }

    fn unary(self: *Parser) ParserError!*Expression {
        switch (self.peek().?) {
            .bang, .minus => {
                const op: UnaryOp = switch (self.peek().?) {
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
        const prim = val: switch (self.peek().?) {
            .ident => |i| {
                self.advance();
                const v = try self.allocator().create(Expression);
                v.* = .{ .variable = i };

                break :val v;
            },
            .keyword => |k| switch (k) {
                .true_key => {
                    self.advance();
                    const boolean = try self.allocator().create(Expression);
                    boolean.* = .{ .literal = .{ .boolean = true } };

                    break :val boolean;
                },
                .false_key => {
                    self.advance();
                    const boolean = try self.allocator().create(Expression);
                    boolean.* = .{ .literal = .{ .boolean = false } };

                    break :val boolean;
                },
                else => return error.UnexpectedKeyword,
            },
            .number => |n| {
                self.advance();
                const num = try self.allocator().create(Expression);
                num.* = .{ .literal = .{ .number = n } };

                break :val num;
            },
            .openparen => {
                self.advance();
                const inner = try self.equality();

                const grouping = try self.allocator().create(Expression);
                grouping.* = .{ .grouping = inner };

                try self.consume(.closeparen);

                break :val grouping;
            },
            else => {
                return error.ExpectedTokenFound;
            },
        };

        return prim;
    }
};
