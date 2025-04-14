//! Main wasm runtime

const console = @import("./wasm/core.zig");
const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const Parser = @import("./parser.zig").Parser;

const expression = @import("./parser/expression.zig");
const Expression = expression.Expression;
const Direction = expression.Direction;

const Evaluator = @import("./evaluator.zig").Evaluator;

pub extern "env" fn updatePosition(x: u32, y: u32) void;
pub extern "env" fn moveRelative(dx: i32, dy: i32) void;

const allocator = std.heap.wasm_allocator;

var pc: usize = 0;
var instructions = std.ArrayList(*Expression).init(allocator);

var parser = Parser.init(null, allocator);
var runtime = Evaluator.init(allocator, .{ .move_fn = enqueue_move, .print_fn = null });

const Move = struct {
    dir: Direction,
};

const MoveQueue = std.DoublyLinkedList(Move);
var move_queue = MoveQueue{};

fn enqueue_move(dir: Direction, amount: usize) void {
    for (0..amount) |_| {
        const mv = Move{ .dir = dir };

        const node = allocator.create(MoveQueue.Node) catch @panic("Allocation problems");
        node.*.data = mv;

        move_queue.append(node);
    }
}

fn move(dir: Direction, amount: usize) void {
    const amnt: i32 = @intCast(amount);
    switch (dir) {
        .left => moveRelative(-amnt, 0),
        .right => moveRelative(amnt, 0),
        .up => moveRelative(0, -amnt),
        .down => moveRelative(0, amnt),
    }
}

export fn alloc(len: u32) [*]const u8 {
    const slice = allocator.alloc(u8, len) catch @panic("Allocating went wrong");
    return slice.ptr;
}

export fn loadProgram(prog: [*]u8, len: usize) i32 {
    loadProgramInner(prog, len) catch |err| switch (err) {
        error.UnreckognizedToken => return -2,
        error.ExpectedTokenFound => return -3,
        error.UnexpectedKeyword => return -4,
        else => return -1,
    };
    return 0;
}

fn loadProgramInner(prog: [*]u8, len: usize) !void {
    instructions.clearAndFree();
    while (move_queue.pop()) |_| {}

    parser.deinit();
    parser = Parser.init(null, allocator);
    pc = 0;

    var stream_buf = std.ArrayList(tokenizer.Token).init(allocator);

    const stream = prog[0..len];
    console.log("'{s}'\n", .{stream});

    try tokenizer.tokenize(stream, &stream_buf, null);

    parser.set_tokens(stream_buf.items);

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
    if (pc < instructions.items.len and move_queue.len == 0) {
        _ = try runtime.eval(instructions.items[pc]);

        pc += 1;
    }

    if (move_queue.popFirst()) |mv| {
        move(mv.*.data.dir, 1);
    }
}
