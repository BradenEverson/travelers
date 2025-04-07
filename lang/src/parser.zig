const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const Expression = @import("./parser/expression.zig").Expression;

const Token = tokenizer.Token;
const TokenTag = tokenizer.TokenTag;

pub const ParseError = error{};

pub const ParserError = ParseError;

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

    pub fn parse(self: *Parser, statements: *std.ArrayList(Expression)) ParserError!void {
        for (self.stream) |elem| {
            std.debug.print("{}\n", .{elem});
        }
        _ = statements;
    }
};
