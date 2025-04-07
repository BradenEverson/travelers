const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const Parser = @import("./parser.zig").Parser;

const ArrayList = std.ArrayList;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var args = std.process.args();
    _ = args.skip();

    const path = args.next() orelse {
        std.debug.print("Please invoke by including a file path\n", .{});
        return;
    };

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const buf = try file.readToEndAlloc(allocator, std.math.maxInt(u32));

    var stream_buf = ArrayList(tokenizer.Token).init(allocator);
    defer stream_buf.deinit();

    var ctx: tokenizer.ErrorContext = undefined;
    tokenizer.tokenize(buf, &stream_buf, &ctx) catch |err| switch (err) {
        error.UnreckognizedToken => {
            const line_start = ctx.target_line.@"0";
            const line_end = ctx.target_line.@"1";
            const invalid_line = buf[line_start..line_end];
            const invalid_token = ctx.token;

            std.debug.print("token error: Unrecognized Token `{c}`\n", .{invalid_token});
            std.debug.print(" -> {s}:{d}:{d}\n", .{ path, ctx.line, ctx.col });
            std.debug.print(" | {s}\n", .{invalid_line});

            var underline = std.ArrayList(u8).init(std.heap.page_allocator);
            defer underline.deinit();

            var i: usize = 1;
            while (i < ctx.col) : (i += 1) {
                try underline.append(' ');
            }

            i = 0;
            while (i < ctx.len) : (i += 1) {
                try underline.append('~');
            }

            std.debug.print(" | {s}\n", .{underline.items});
            return;
        },
        else => {
            std.debug.print("Other Error: {}\n", .{err});
            return;
        },
    };

    for (stream_buf.items) |elem| {
        std.debug.print("{}\n", .{elem});
    }

    const parser = Parser{ .stream = stream_buf.items };
    _ = parser;
}
