//! External JS Binding Function Definitions

pub extern "env" fn moveRelative(dx: i32, dy: i32) i32;
pub extern "env" fn lookAtRelative(dx: i32, dy: i32) i32;
pub extern "env" fn attackAt(dx: i32, dy: i32) i32;
pub extern "env" fn trapAt(dx: i32, dy: i32) bool;
pub extern "env" fn updateHealthBar(hp: u8) void;
