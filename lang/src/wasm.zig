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
    updatePosition(15, 15);
}
