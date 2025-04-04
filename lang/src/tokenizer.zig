const std = @import("std");
const ArrayList = std.ArrayList;
const PeekableIterator = @import("./tokenizer/peekable.zig").PeekableIterator;

pub const Token = struct {
    tag: TokenTag,
    line: u32,
    col: u32,
    len: u32,

    pub fn format(
        self: *const Token,
        _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{{ {}, line: {}, column: {}, length: {} }}", .{ self.tag, self.line, self.col, self.len });
    }
};

pub const TokenTag = union(enum) {
    ident: []const u8,
    plus,
    minus,
    star,
    slash,
    newline,

    pub fn format(self: *const TokenTag, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self.*) {
            .ident => |ident| {
                try writer.print("Identifier: \"{s}\"", .{ident});
            },

            .plus => try writer.print("Plus", .{}),
            .minus => try writer.print("Minus", .{}),
            .newline => try writer.print("Newline", .{}),
            .star => try writer.print("Star", .{}),
            .slash => try writer.print("Slash", .{}),
        }
    }
};

pub fn tokenize(stream: []const u8, buf: *ArrayList(Token)) !void {
    var peek = PeekableIterator{ .buf = stream };

    while (peek.next()) |tok| {
        _ = switch (tok) {
            '+' => TokenTag.plus,
            '-' => TokenTag.minus,
            '/' => TokenTag.slash,
            '*' => TokenTag.star,

            '\n' => TokenTag.newline,

            '\t', ' ' => continue,
            else => continue,
        };
    }

    const token = Token{
        .tag = TokenTag{ .ident = "Hello!" },
        .col = 0,
        .line = 0,
        .len = 6,
    };

    try buf.append(token);
}
