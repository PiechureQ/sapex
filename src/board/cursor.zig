const std = @import("std");
const testing = @import("std").testing;
const Pos = @import("./entity.zig").Pos;
const Board = @import("./board.zig").Board;

pub const Cursor = struct {
    const display: []const u8 = "c";

    min_x: i8 = 0,
    max_x: i8,
    min_y: i8 = 0,
    max_y: i8,

    pos: Pos,

    pub fn init(max_x: u8, max_y: u8) Cursor {
        // std.debug.print("max h {} w {} \n", .{ board.h, board.w });
        // std.process.exit(2);
        return .{
            .max_y = @intCast(max_x - 1),
            .max_x = @intCast(max_y - 1),
            .pos = Pos.init(),
        };
    }

    pub fn draw(self: *Cursor) []const u8 {
        _ = self;
        return display;
    }

    pub fn move(self: *Cursor, x: i8, y: i8) void {
        self.setPos(x, y);
    }

    pub fn moveBy(self: *Cursor, x: i8, y: i8) void {
        self.setPos(self.pos.x + x, self.pos.y + y);
    }

    pub fn moveXBy(self: *Cursor, x: i8) void {
        self.moveBy(x, 0);
    }

    pub fn moveYBy(self: *Cursor, y: i8) void {
        self.moveBy(0, y);
    }

    pub fn getPos(self: *Cursor) *Pos {
        return &self.pos;
    }

    fn setPos(self: *Cursor, x: i8, y: i8) void {
        self.pos.set(@max(self.min_x, @min(self.max_x, x)), @max(self.min_y, @min(self.max_y, y)));
    }
};

test "move changes pos" {
    const cur = Cursor{ .max_y = 2, .max_x = 2 };
    cur.move(1, 2);
    try testing.expectEqual(cur.getPos().x, 1);
    try testing.expectEqual(cur.getPos().y, 2);
}

test "respect min/max" {
    const cur = Cursor{ .min_y = 0, .min_x = 0, .max_y = 2, .max_x = 2 };
    cur.move(-1, 3);
    try testing.expectEqual(cur.getPos().x, 0);
    try testing.expectEqual(cur.getPos().y, 2);
}

test "draw" {
    const cur = Cursor{ .max_y = 2, .max_x = 2 };

    try testing.expectEqual(cur.draw(), Cursor.display);
}
