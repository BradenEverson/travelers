const std = @import("std");

pub const PeekableIterator = struct {
    buf: []const u8,
    index: usize = 0,

    pub fn next(self: *PeekableIterator) ?u8 {
        if (self.index < self.buf.len) {
            self.index += 1;
            return self.buf[self.index - 1];
        }

        return null;
    }

    pub fn peek(self: *PeekableIterator) ?u8 {
        if (self.index < self.buf.len) {
            return self.buf[self.index];
        }

        return null;
    }
};
