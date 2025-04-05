const std = @import("std");
const tokenizer = @import("./tokenizer.zig");

const Token = tokenizer.Token;
const TokenTag = tokenizer.TokenTag;

pub const Parser = struct {
    stream: []const Token,
    index: usize = 0,

    pub fn parse(self: *Parser) void {
        _ = self;
    }
};
