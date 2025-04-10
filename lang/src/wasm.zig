//! Main wasm runtime

pub extern "env" fn updatePosition(x: u32, y: u32) void;
pub extern "env" fn moveRelative(dx: i32, dy: i32) void;

export fn moveRoutine() void {
    updatePosition(16, 16);

    moveRelative(5, 0);
    moveRelative(-5, 0);
    moveRelative(0, 10);
    moveRelative(3, -2);
}
