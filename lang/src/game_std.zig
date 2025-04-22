pub const TileType = enum {
    open,
    enemy,
    rock,
    wood,

    pub fn from_int(from: i32) ?TileType {
        return switch (from) {
            0 => .open,
            1 => .enemy,
            2 => .rock,
            3 => .wood,
            else => null,
        };
    }
};

pub const Unit = struct {
    health: u8,
    atk: u8,
    range: u8,
    material: u8,

    /// A default player starts with 100 health, 5 attack damange,
    /// a tile range of 1 and 2 materials to place down
    pub fn default() Unit {
        return .{
            .health = 100,
            .atk = 5,
            .range = 1,
            .material = 2,
        };
    }
};
