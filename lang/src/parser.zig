const std = @import("std");
const tokenizer = @import("./tokenizer.zig");

const Token = tokenizer.Token;
const TokenTag = tokenizer.TokenTag;

pub const Parser = struct {
    stream: []const Token,
    index: usize = 0,

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

    pub fn parse(self: *Parser) void {
        _ = self;
    }
};
