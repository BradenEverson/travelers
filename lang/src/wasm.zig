//! Main wasm runtime

const std = @import("std");
const Expression = @import("./parser/expression.zig").Expression;
const tokenizer = @import("./tokenizer.zig");
const Parser = @import("./parser.zig").Parser;

pub extern "env" fn updatePosition(x: u32, y: u32) void;
pub extern "env" fn moveRelative(dx: i32, dy: i32) void;

const allocator = std.heap.wasm_allocator;

var pc: usize = 0;
var instructions = std.ArrayList(*Expression).init(allocator);
var parser = Parser.init(null, allocator);

export fn alloc(len: u32) [*]const u8 {
    const slice = allocator.alloc(u8, len) catch @panic("Allocating went wrong");
    return slice.ptr;
}

export fn loadProgram(prog: [*]u8, len: usize) i32 {
    loadProgramInner(prog, len) catch {
        return -1;
    };
    return 0;
}

fn loadProgramInner(prog: [*]u8, len: usize) !void {
    var stream_buf = std.ArrayList(tokenizer.Token).init(allocator);
    defer stream_buf.deinit();

    const stream = prog[0..len];
    try tokenizer.tokenize(stream, &stream_buf, null);

    try parser.parse(&instructions);
}

/// Steps the runtime by one frame, performs a single statement and updates position as such
export fn step() i32 {
    stepInner() catch {
        return -1;
    };
    return 0;
}

/// Internal step function that can return an error, masked by the exported step function
fn stepInner() !void {
    if (pc >= 32) {
        pc = 0;
        // return;
    }

    updatePosition(pc, pc);

    pc += 1;
}
