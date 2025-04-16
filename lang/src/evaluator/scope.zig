const std = @import("std");
const Literal = @import("../parser/expression.zig").Literal;

pub const OwnedScope = struct {
    allocator: std.mem.Allocator,
    map: std.StringHashMap(Literal),

    pub fn init(allocator: std.mem.Allocator) OwnedScope {
        return OwnedScope{
            .allocator = allocator,
            .map = std.StringHashMap(Literal).init(allocator),
        };
    }

    pub fn get(self: *OwnedScope, key: []const u8) ?Literal {
        return self.map.get(key);
    }

    /// Registers an unowned name into a scoped variable and assigns it to the value
    pub fn register(self: *OwnedScope, key: []const u8, val: Literal) !void {
        const owned = try self.allocator.dupe(u8, key);
        try self.map.put(owned, val);
    }
};
