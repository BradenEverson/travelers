//! Main wasm runtime

const std = @import("std");

pub extern "env" fn updatePosition(x: u32, y: u32) void;
pub extern "env" fn moveRelative(dx: i32, dy: i32) void;

const allocator = std.heap.wasm_allocator;

export fn moveRoutine() i32 {
    moveRountineInner() catch {
        return -1;
    };
    return 0;
}

fn moveRountineInner() !void {
    const Move = struct {
        dx: i32,
        dy: i32,
    };

    var moves = std.ArrayList(Move).init(allocator);
    defer moves.deinit();

    try moves.append(.{ .dy = 1, .dx = -1 });
    try moves.append(.{ .dy = 5, .dx = 6 });
    try moves.append(.{ .dy = -10, .dx = 0 });
    try moves.append(.{ .dy = 1, .dx = -1 });

    updatePosition(16, 16);

    for (moves.items) |move| {
        moveRelative(move.dx, move.dy);
    }
}
