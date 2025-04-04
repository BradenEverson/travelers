const ArrayList = @import("std").ArrayList;

pub const Token = struct {
    tag: TokenTag,
    line: u32,
    col: u32,
    len: u32,
};

pub const TokenTag = union(enum) {
    ident: []const u8,
};

pub fn tokenize(stream: []const u8, buf: *ArrayList(Token)) !void {
    _ = stream;

    const token = Token{
        .tag = TokenTag{ .ident = "Hello!" },
        .col = 0,
        .line = 0,
        .len = 6,
    };

    try buf.append(token);
}
