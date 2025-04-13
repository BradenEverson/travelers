//! Main wasm runtime

const std = @import("std");
const Expression = @import("./parser/expression.zig").Expression;
const tokenizer = @import("./tokenizer.zig");
const Parser = @import("./parser.zig").Parser;
const Evaluator = @import("./evaluator.zig").Evaluator;
const Direction = @import("./evaluator.zig").Direction;

pub extern "env" fn updatePosition(x: u32, y: u32) void;
pub extern "env" fn moveRelative(dx: i32, dy: i32) void;
pub extern "env" fn log(ptr: [*]const u8, len: usize) void;

const allocator = std.heap.wasm_allocator;

var pc: usize = 0;
var instructions = std.ArrayList(*Expression).init(allocator);
var parser = Parser.init(null, allocator);
var runtime = Evaluator.init(allocator, .{ .move_fn = move, .print_fn = null });

fn move(dir: Direction, amount: i32) void {
    switch (dir) {
        .left => moveRelative(-amount, 0),
        .right => moveRelative(amount, 0),
        .up => moveRelative(0, -amount),
        .down => moveRelative(0, amount),
    }
}

fn consoleLog(msg: []const u8) void {
    log(msg.ptr, msg.len);
}

export fn alloc(len: u32) [*]const u8 {
    const slice = allocator.alloc(u8, len) catch @panic("Allocating went wrong");
    return slice.ptr;
}

export fn loadProgram(prog: [*]u8, len: usize) i32 {
    loadProgramInner(prog, len) catch |err| switch (err) {
        error.UnreckognizedToken => return -2,
        error.ExpectedTokenFound => return -3,
        else => return -1,
    };
    return 0;
}

fn loadProgramInner(prog: [*]u8, len: usize) !void {
    var stream_buf = std.ArrayList(tokenizer.Token).init(allocator);
    defer stream_buf.deinit();

    const stream = prog[0..len];
    const string = try std.fmt.allocPrint(allocator, "'{s}'\n", .{stream});
    consoleLog(string);

    try tokenizer.tokenize(stream, &stream_buf, null);

    parser.set_tokens(stream_buf.items);

    try parser.parse(&instructions);
    pc = 0;
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
    if (pc >= instructions.items.len) {
        return;
    }

    _ = try runtime.eval(instructions.items[pc]);

    pc += 1;
}
