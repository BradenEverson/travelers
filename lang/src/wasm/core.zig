//! Core WASM module stuff

extern "env" fn log_js(ptr: [*]const u8, len: usize) void;

pub fn log(msg: []const u8) void {
    log_js(msg.ptr, msg.len);
}
