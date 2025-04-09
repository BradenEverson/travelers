const std = @import("std");
const PeekableIterator = @import("./tokenizer/peekable.zig").PeekableIterator;
const ArrayList = std.ArrayList;

pub const TokenError = error{
    UnreckognizedToken,
};

pub const ErrorContext = struct {
    target_line: struct { usize, usize },
    token: u8,
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

pub const Keyword = enum {
    left,
    right,
    up,
    down,

    const mappings = std.StaticStringMap(Keyword).initComptime(.{
        .{ "left", .left },
        .{ "right", .right },
        .{ "up", .up },
        .{ "down", .down },
    });

    pub fn format(self: *const Keyword, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self.*) {
            .left => try writer.print("left", .{}),
            .right => try writer.print("right", .{}),
            .up => try writer.print("up", .{}),
            .down => try writer.print("down", .{}),
        }
    }

    pub fn tryFromString(string: []const u8) ?Keyword {
        return mappings.get(string);
    }
};

pub const TokenTag = union(enum) {
    ident: []const u8,
    keyword: Keyword,
    number: f32,
    plus,
    bang,
    bangequal,
    equalequal,
    equals,
    gt,
    gte,
    lt,
    lte,
    minus,
    star,
    slash,
    semicolon,
    openparen,
    closeparen,
    eof,

    pub fn format(self: *const TokenTag, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self.*) {
            .ident => |ident| {
                try writer.print("Identifier: \"{s}\"", .{ident});
            },

            .number => |n| {
                try writer.print("Number: \"{d:.2}\"", .{n});
            },

            .keyword => |k| {
                try writer.print("Keyword: \"{}\"", .{k});
            },

            .plus => try writer.print("Plus", .{}),
            .minus => try writer.print("Minus", .{}),
            .bang => try writer.print("Bang", .{}),
            .bangequal => try writer.print("Inequality", .{}),
            .equalequal => try writer.print("Equality", .{}),
            .equals => try writer.print("Equals", .{}),
            .gt => try writer.print("GT", .{}),
            .gte => try writer.print("GTE", .{}),
            .lt => try writer.print("LT", .{}),
            .openparen => try writer.print("OpenParen", .{}),
            .closeparen => try writer.print("CloseParen", .{}),
            .lte => try writer.print("LTE", .{}),
            .star => try writer.print("Star", .{}),
            .semicolon => try writer.print("Semicolon", .{}),
            .slash => try writer.print("Slash", .{}),
            .eof => try writer.print("EOF", .{}),
        }
    }
};

pub const TokenizeError = TokenError || std.mem.Allocator.Error;

pub fn tokenize(stream: []const u8, buf: *ArrayList(Token), err_ctx: *ErrorContext) TokenizeError!void {
    var peek = PeekableIterator(u8){ .buf = stream };

    var line: u32 = 1;
    var col: u32 = 1;
    var len: u32 = 1;

    var line_start: usize = 0;
    var current_line_end: usize = 0;

    while (peek.next()) |tok| {
        len = 1;
        const next: TokenTag = switch (tok) {
            '+' => .plus,
            '-' => .minus,
            '/' => .slash,
            '*' => .star,
            ';' => .semicolon,

            '(' => .openparen,
            ')' => .closeparen,

            '<' => lt: {
                if (peek.peek() == '=') {
                    _ = peek.next();
                    break :lt .lte;
                } else {
                    break :lt .lt;
                }
            },

            '>' => gt: {
                if (peek.peek() == '=') {
                    _ = peek.next();
                    break :gt .gte;
                } else {
                    break :gt .gt;
                }
            },

            '!' => bang: {
                if (peek.peek() == '=') {
                    _ = peek.next();
                    break :bang .bangequal;
                } else {
                    break :bang .bang;
                }
            },

            '=' => eq: {
                if (peek.peek() == '=') {
                    _ = peek.next();
                    break :eq .equalequal;
                } else {
                    break :eq .equals;
                }
            },

            '\n' => {
                col = 1;
                line += 1;
                current_line_end += 1;
                line_start = current_line_end;
                continue;
            },

            '\t', ' ' => {
                col += 1;
                current_line_end += 1;
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

                    col += len - 1;
                    current_line_end += len - 1;

                    if (Keyword.tryFromString(word)) |keyword| {
                        break :ident TokenTag{ .keyword = keyword };
                    } else {
                        break :ident TokenTag{ .ident = word };
                    }
                } else if (isNumeric(tok)) {
                    const start = peek.index - 1;

                    while (peek.peek()) |peek_tok| {
                        if (!isNumeric(peek_tok)) {
                            break;
                        }
                        len += 1;
                        _ = peek.next();
                    }

                    col += len - 1;
                    current_line_end += len - 1;

                    const end = peek.index;
                    const word = stream[start..end];

                    const parse = std.fmt.parseFloat(f32, word) catch unreachable;

                    break :ident TokenTag{ .number = parse };
                } else {
                    var error_end = current_line_end;
                    while (peek.peek()) |val| {
                        error_end += 1;
                        if (val == '\n') break;
                        _ = peek.next();
                    }

                    err_ctx.*.col = col;
                    err_ctx.*.token = tok;
                    err_ctx.*.line = line;
                    err_ctx.*.len = len;
                    err_ctx.*.target_line = .{ line_start, error_end };
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

        current_line_end += 1;
        col += 1;

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
