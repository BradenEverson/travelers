const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const Expression = @import("./parser/expression.zig").Expression;

const Token = tokenizer.Token;
const TokenTag = tokenizer.TokenTag;

pub const ParseError = error{};

pub const ParserError = ParseError || std.mem.Allocator.Error;

pub const Parser = struct {
    stream: []const Token,
    index: usize = 0,
    allocator: std.heap.ArenaAllocator,

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

    fn at_end(self: *Parser) bool {
        return self.peek() == .eof;
    }

    pub fn parse(self: *Parser, statements: *std.ArrayList(Expression)) ParserError!void {
        while (!self.at_end()) : (self.advance()) {
            const s = try self.statement();
            try statements.append(s);
        }
    }

    fn statement(self: *Parser) ParserError!Expression {
        const tag = self.peek();
        return switch (tag) {
            else => try self.expression(),
        };
    }

    fn expression(self: *Parser) ParserError!Expression {
        _ = self;
        @panic("Todo!");
    }
};
