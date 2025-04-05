const std = @import("std");

pub fn PeekableIterator(comptime T: type) type {
    return struct {
        buf: []const T,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            if (self.index < self.buf.len) {
                self.index += 1;
                return self.buf[self.index - 1];
            }

            return null;
        }

        pub fn peek(self: *Self) ?T {
            if (self.index < self.buf.len) {
                return self.buf[self.index];
            }

            return null;
        }
    };
}
