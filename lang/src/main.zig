const std = @import("std");
const tokenizer = @import("./tokenizer.zig");

const ArrayList = std.ArrayList;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var args = std.process.args();
    _ = args.skip();

    const path = args.next() orelse {
        std.debug.print("Please invoke by including a file path\n", .{});
        return;
    };

    std.debug.print("{s}\n", .{path});

    var stream_buf = ArrayList(tokenizer.Token).init(allocator);
    defer stream_buf.deinit();

    try tokenizer.tokenize("", &stream_buf);

    const elem = stream_buf.items[0];
    std.debug.print("{}\n", .{elem});
}
