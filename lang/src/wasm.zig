//! Main wasm runtime

const std = @import("std");

pub extern "env" fn updatePosition(x: u32, y: u32) void;
pub extern "env" fn moveRelative(dx: i32, dy: i32) void;

var global_buf: [2048]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&global_buf);
const allocator = fba.allocator();

export fn moveRoutine() i32 {
    moveRountineInner() catch {
        return -1;
    };
    return 0;
}

fn moveRountineInner() !void {
    var moves = std.ArrayList(u32).init(allocator);
    defer moves.deinit();

    try moves.append(1);
    try moves.append(2);
    try moves.append(1);
    try moves.append(3);

    for (moves.items) |move| {
        updatePosition(move, move);
    }
}
