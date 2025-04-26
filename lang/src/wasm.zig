//! Main wasm runtime

const console = @import("./wasm/core.zig");
const std = @import("std");
const tokenizer = @import("./tokenizer.zig");
const Parser = @import("./parser.zig").Parser;

const expression = @import("./parser/expression.zig");
const Expression = expression.Expression;
const Direction = expression.Direction;
const Literal = expression.Literal;

const game = @import("game_std.zig");
const Unit = game.Unit;
const TileType = game.TileType;

const Evaluator = @import("./evaluator.zig").Evaluator;

pub extern "env" fn updatePosition(x: u32, y: u32) void;
pub extern "env" fn moveRelative(dx: i32, dy: i32) i32;
pub extern "env" fn lookAtRelative(dx: i32, dy: i32) i32;
pub extern "env" fn attackAt(dx: i32, dy: i32) i32;
pub extern "env" fn trapAt(dx: i32, dy: i32) bool;
pub extern "env" fn updateHealthBar(hp: u8) void;

pub fn print(l: Literal) void {
    console.log("{}", .{l});
}

pub fn lookAt(dx: i32, dy: i32) TileType {
    return TileType.from_int(lookAtRelative(dx, dy)) orelse .border;
}

const allocator = std.heap.wasm_allocator;

var pc: usize = 0;
var instructions = std.ArrayList(*const Expression).init(allocator);
var player = Unit.default();

export fn doDamage(dmg: u8) void {
    player.health -|= dmg;
    updateHealthBar(player.health);
}

var parser = Parser.init(null, allocator);
var runtime = Evaluator.init(allocator, .{ .move_fn = enqueueMove, .print_fn = print, .block_fn = blockStatement, .while_fn = whileStatement, .peek_fn = peekAt, .attack_fn = attack, .trap_fn = placeTrap });

const Action = union(enum) {
    move: Direction,
};

const MoveQueue = std.DoublyLinkedList(Action);
var move_queue = MoveQueue{};

fn attack(dir: Direction) TileType {
    const attacked = switch (dir) {
        .up => attackAt(0, -1),
        .down => attackAt(0, 1),
        .left => attackAt(-1, 0),
        .right => attackAt(1, 0),
    };

    const tile = TileType.from_int(attacked) orelse .border;

    if (std.meta.eql(tile, .wood)) {
        player.material += 1;
    }

    return tile;
}

fn peekAt(dir: Direction) TileType {
    const peek = switch (dir) {
        .up => lookAt(0, -1),
        .down => lookAt(0, 1),
        .left => lookAt(-1, 0),
        .right => lookAt(1, 0),
    };

    return peek;
}

fn placeTrap(dir: Direction) bool {
    if (player.material < 3) {
        return false;
    }

    const trap = switch (dir) {
        .up => trapAt(0, -1),
        .down => trapAt(0, 1),
        .left => trapAt(-1, 0),
        .right => trapAt(1, 0),
    };

    if (trap) {
        player.material -= 3;
    }

    return trap;
}

fn enqueueMove(dir: Direction, amount: usize) void {
    for (0..amount) |_| {
        const mv = Action{ .move = dir };

        const node = allocator.create(MoveQueue.Node) catch @panic("Allocation problems");
        node.*.data = mv;

        move_queue.append(node);
    }
}

fn whileStatement(pushed: *const Expression) void {
    const curr = instructions.items[pc];
    instructions.insert(pc + 1, pushed) catch @panic("Big Problem");
    instructions.insert(pc + 2, curr) catch @panic("Big Problem");
}

fn blockStatement(block: []*const Expression) void {
    pc += 1;
    const tmp = pc;
    for (block) |b| {
        instructions.insert(pc, b) catch @panic("Big Problem");
        pc += 1;
    }

    pc = tmp - 1;
}

fn move(dir: Direction, amount: usize) void {
    const amnt: i32 = @intCast(amount);
    const res = switch (dir) {
        .left => moveRelative(-amnt, 0),
        .right => moveRelative(amnt, 0),
        .up => moveRelative(0, -amnt),
        .down => moveRelative(0, amnt),
    };

    if (res == -2) {
        doDamage(20);
    }
}

export fn getHealth() u8 {
    return player.health;
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
    runtime.reset();
    instructions.clearAndFree();
    while (move_queue.pop()) |_| {}

    parser.deinit();
    parser = Parser.init(null, allocator);
    pc = 0;

    var stream_buf = std.ArrayList(tokenizer.Token).init(allocator);

    const stream = prog[0..len];

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
        const curr = instructions.items[pc];
        _ = try runtime.eval(curr);

        pc += 1;
    }

    if (move_queue.popFirst()) |mv| {
        switch (mv.*.data) {
            .move => |dir| move(dir, 1),
        }
    }
}
