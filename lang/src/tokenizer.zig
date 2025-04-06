const std = @import("std");
const PeekableIterator = @import("./tokenizer/peekable.zig").PeekableIterator;
const ArrayList = std.ArrayList;

pub const TokenizeError = error{
    UnrecognizedToken,
};

pub const ErrorContext = struct {
    line: u32,
    col: u32,
    len: u32,
};

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
    number: f32,
    plus,
    minus,
    star,
    slash,
    semicolon,
    eof,

    pub fn format(self: *const TokenTag, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self.*) {
            .ident => |ident| {
                try writer.print("Identifier: \"{s}\"", .{ident});
            },

            .number => |n| {
                try writer.print("Number: \"{d:.2}\"", .{n});
            },

            .plus => try writer.print("Plus", .{}),
            .minus => try writer.print("Minus", .{}),
            .star => try writer.print("Star", .{}),
            .semicolon => try writer.print("Semicolon", .{}),
            .slash => try writer.print("Slash", .{}),
            .eof => try writer.print("EOF", .{}),
        }
    }
};

pub fn tokenize(stream: []const u8, buf: *ArrayList(Token), err_ctx: *ErrorContext) !void {
    var peek = PeekableIterator(u8){ .buf = stream };

    var line: u32 = 1;
    var col: u32 = 1;
    var len: u32 = 1;

    while (peek.next()) |tok| {
        len = 1;
        col += 1;
        const next = switch (tok) {
            '+' => .plus,
            '-' => .minus,
            '/' => .slash,
            '*' => .star,
            ';' => .semicolon,

            '\n' => {
                col = 1;
                line += 1;
                continue;
            },

            '\t', ' ' => {
                col += 1;
                continue;
            },

            else => ident: {
                if (std.ascii.isAlphabetic(tok)) {
                    const start = peek.index - 1;

                    while (peek.peek()) |peek_tok| {
                        if (!std.ascii.isAlphanumeric(peek_tok)) {
                            break;
                        }
                        len += 1;
                        _ = peek.next();
                    }

                    const end = peek.index;
                    const word = stream[start..end];

                    break :ident TokenTag{ .ident = word };
                } else if (isNumeric(tok)) {
                    const start = peek.index - 1;

                    while (peek.peek()) |peek_tok| {
                        if (!isNumeric(peek_tok)) {
                            break;
                        }
                        len += 1;
                        _ = peek.next();
                    }

                    const end = peek.index;
                    const word = stream[start..end];

                    const parse = std.fmt.parseFloat(f32, word) catch unreachable;

                    break :ident TokenTag{ .number = parse };
                } else {
                    err_ctx.*.col = col;
                    err_ctx.*.line = line;
                    err_ctx.*.len = len;
                    return error.UnreckognizedToken;
                }
            },
        };

        const token = Token{
            .tag = next,
            .col = col,
            .line = line,
            .len = len,
        };

        try buf.append(token);
    }

    try buf.append(Token{
        .tag = TokenTag.eof,
        .col = col,
        .line = line,
        .len = len,
    });
}

pub fn isNumeric(tok: u8) bool {
    return std.ascii.isDigit(tok) or tok == '.';
}
