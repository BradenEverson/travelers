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
            std.debug.print("Unreckognized Token:\n", .{});
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
