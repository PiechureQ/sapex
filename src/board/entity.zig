pub const Pos = struct {
    x: i8 = 0,
    y: i8 = 0,

    pub fn set(self: *Pos, x: i8, y: i8) void {
        self.x = x;
        self.y = y;
    }

    pub fn init() Pos {
        return .{};
    }
};
