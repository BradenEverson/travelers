//! Main wasm runtime

pub extern "env" fn updatePosition(x: u32, y: u32) void;

export fn move(x: u32, y: u32) void {
    updatePosition(x, y);
}
