const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const Expression = @import("./parser/expression.zig").Expression;

const Token = tokenizer.Token;
const TokenTag = tokenizer.TokenTag;

pub const ParseError = error{ExpectedTokenFound};

pub const ParserError = ParseError || std.mem.Allocator.Error;

pub const Parser = struct {
    stream: []const Token,
    index: usize = 0,
    allocator: std.mem.Allocator,

    fn peek(self: *Parser) TokenTag {
        return self.stream[self.index].tag;
    }

    fn advance(self: *Parser) void {
        if (self.index >= self.stream.len) {
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
        return switch (tag) {
            else => expr: {
                const e = try self.expression();
                try self.consume(.semicolon);
                break :expr e;
            },
        };
    }

    fn expression(self: *Parser) ParserError!*Expression {
        return switch (self.peek()) {
            else => try self.equality(),
        };
    }

    fn equality(self: *Parser) ParserError!*Expression {
        _ = self;
        @panic("todo");
    }

    fn comparison(self: *Parser) ParserError!*Expression {
        _ = self;
        @panic("todo");
    }

    fn term(self: *Parser) ParserError!*Expression {
        _ = self;
        @panic("todo");
    }

    fn factor(self: *Parser) ParserError!*Expression {
        _ = self;
        @panic("todo");
    }

    fn unary(self: *Parser) ParserError!*Expression {
        _ = self;
        @panic("todo");
    }

    fn primary(self: *Parser) ParserError!*Expression {
        _ = self;
        @panic("todo");
    }
};
