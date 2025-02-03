const std = @import("std");
const ArrayList = std.ArrayList;
const testing = std.testing;
const Pos = @import("./entity.zig").Pos;

const Field = struct {
    surrounds: u8 = 0,
    mine: bool,
    exposed: bool = false,
    flag: bool = false,

    pub fn draw(self: *Field) []const u8 {
        if (self.exposed) {
            if (self.mine) {
                return "x";
            } else {
                const a = switch (self.surrounds) {
                    1 => "1",
                    2 => "2",
                    3 => "3",
                    4 => "4",
                    5 => "5",
                    6 => "6",
                    7 => "7",
                    8 => "8",
                    else => "_",
                };
                return a;
            }
        } else if (self.flag) {
            return "P";
        } else {
            return "o";
        }
    }

    pub fn setExposed(self: *Field) void {
        if (self.flag != true) {
            self.exposed = true;
        }
    }

    pub fn toggleFlag(self: *Field) void {
        if (self.exposed != true) {
            self.flag = !self.flag;
        }
    }
};

const BoardError = error{
    AccessOutOfBounds,
};

pub const Board = struct {
    allocator: std.mem.Allocator,
    fields: []Field,

    w: u8,
    h: u8,
    mines_count: u8,

    pub fn init(alloc: std.mem.Allocator, w: u8, h: u8, mines_count: u8) !Board {
        var board = Board{
            .w = w,
            .h = h,
            .mines_count = mines_count,
            .fields = try generateBoard(alloc, w, h, mines_count),
            .allocator = alloc,
        };
        board.calculateSurrounding();
        return board;
    }

    pub fn deinit(self: *Board) void {
        self.allocator.free(self.fields);
    }

    pub fn getPosIndex(self: *Board, x: i8, y: i8) !usize { // {{{
        if (x >= 0 and x < self.w and y >= 0 and y < self.h) {
            const fx: usize = @intCast(x);
            const fy: usize = @intCast(y);
            return @as(usize, fy * self.w + fx);
        } else {
            return BoardError.AccessOutOfBounds;
        }
    }

    pub fn getIndexPos(self: *Board, index: usize) !Pos {
        if (index >= 0 and index < self.w * self.h) {
            const w: i8 = @intCast(self.w);
            const i: i8 = @intCast(index);
            const y: i8 = @divFloor(i, w);
            const x: i8 = i - y * w;
            return Pos{ .x = x, .y = y };
        } else {
            return BoardError.AccessOutOfBounds;
        }
    }

    pub fn getField(self: *Board, x: i8, y: i8) ?*Field {
        const i: usize = self.getPosIndex(x, y) catch return null;
        return &self.fields[i];
    }
    pub fn getFieldByIndex(self: *Board, i: usize) *Field {
        return &self.fields[i];
    } // }}}

    pub fn draw(self: *Board) !struct { buffer: []u8, allocator: std.mem.Allocator } {
        const d_board = try self.allocator.alloc(u8, self.fields.len);
        for (self.fields, 0..) |*field, i| {
            d_board[i] = field.draw()[0];
        }

        return .{ .buffer = d_board, .allocator = self.allocator };
    }

    pub fn isCompleted(self: *Board) bool { // {{{
        return getRemainingCount(self.fields) == 0;
    } // }}}
    //

    pub fn expose(self: *Board, i: usize) void {
        var field = self.getFieldByIndex(i);

        if (field.exposed) return;

        field.setExposed();
        if (field.mine) return;

        if (field.surrounds == 0 and field.flag == false) {
            const srd = self.getSurroundingIndexes(i) catch return;
            defer srd.deinit();
            for (srd.items) |srd_idx| {
                self.expose(srd_idx);
            }
        }
    }

    pub fn getRemaining(self: *Board) i8 {
        return @as(i8, @intCast(getMinesCount(self.fields))) - @as(i8, @intCast(getFlagged(self.fields)));
    }

    fn getSurroundingIndexes(self: *Board, i: usize) !ArrayList(usize) { // {{{
        const my_pos = try self.getIndexPos(i);
        var sr_idxs = ArrayList(usize).init(self.allocator);
        for (0..9) |_si| {
            const si: i8 = @intCast(_si);

            if (si == 4) continue;
            const six = -1 + @mod(si, 3);
            const siy = -1 + @divFloor(si, 3);
            const indexx = self.getPosIndex(my_pos.x + six, my_pos.y + siy) catch continue;
            try sr_idxs.append(indexx);
        }
        return sr_idxs;
    } // }}}

    fn getSurrounding(self: *Board, i: usize) !ArrayList(Field) { // {{{
        const sr_idxs = try self.getSurroundingIndexes(i);
        defer sr_idxs.deinit();

        var surrounding = ArrayList(Field).init(self.allocator);
        for (sr_idxs.items) |sidx| {
            try surrounding.append(self.getFieldByIndex(sidx).*);
        }

        return surrounding;
    }

    fn calculateSurrounding(self: *Board) void {
        // set fields surrounding count
        for (self.fields, 0..) |*field, i| {
            const surrounding = self.getSurrounding(i) catch continue;
            defer surrounding.deinit();
            field.surrounds = getMinesCount(surrounding.items);
        }
    } // }}}
};

fn getMinesCount(fields: []Field) u8 { // {{{
    var count: u8 = 0;
    for (fields) |field| {
        if (field.mine) {
            count += 1;
        }
    }
    return count;
}
fn getRemainingCount(fields: []Field) u8 {
    return getHiddenCount(fields) - getMinesCount(fields);
}
fn getExposedCount(fields: []Field) u8 {
    var count: u8 = 0;
    for (fields) |field| {
        if (field.exposed) {
            count += 1;
        }
    }
    return count;
}
fn getHiddenCount(fields: []Field) u8 {
    return @as(u8, @intCast(fields.len)) - getExposedCount(fields);
}
fn getFlagged(fields: []Field) u8 {
    var count: u8 = 0;
    for (fields) |field| {
        if (field.flag) {
            count += 1;
        }
    }
    return count;
} // }}}

fn generateBoard(allocator: std.mem.Allocator, w: u8, h: u8, mc: u8) ![]Field { // {{{
    const size: usize = @as(usize, w * h);
    // const size = w * h;
    var mines = mc;

    const fields = try allocator.alloc(Field, size);
    // defer allocator.free(fields);

    // initialize board with mines
    var n: u8 = 0;
    while (mines > 0) {
        n += 1;
        for (fields) |*field| {
            var is_mine = false;
            if (mines > 0) {
                is_mine = std.crypto.random.boolean();
                if (is_mine) {
                    mines -= 1;
                }
            }
            if (n > 0) {
                field.mine = is_mine;
            } else {
                field.* = Field{ .mine = is_mine };
            }
        }
    }

    return fields;
} // }}}

test "getPosIndex x < 0 -> error" { // {{{
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    _ = board.getPosIndex(-1, 0) catch |err| {
        try testing.expectEqual(error.AccessOutOfBounds, err);
        return;
    };
    try testing.expect(false);
}
test "getPosIndex y < 0 -> error" {
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    _ = board.getPosIndex(0, -1) catch |err| {
        try testing.expectEqual(error.AccessOutOfBounds, err);
        return;
    };
    try testing.expect(false);
}
test "getPosIndex x >= w -> error" {
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    _ = board.getPosIndex(6, 3) catch |err| {
        try testing.expectEqual(error.AccessOutOfBounds, err);
        return;
    };
    try testing.expect(false);
}
test "getPosIndex y >= h -> error" {
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    _ = board.getPosIndex(3, 5) catch |err| {
        try testing.expectEqual(error.AccessOutOfBounds, err);
        return;
    };
    try testing.expect(false);
}
test "getPosIndex x, y in bounds -> y * w + x" {
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    try testing.expectEqual(board.getPosIndex(3, 2), 2 * 6 + 3);
} // }}}

// test "should generate w * h size fields array" {{{{
//     const a = std.heap.page_allocator;
//     const board = try Board.init(a, 6, 5, 10);
//
//     try testing.expectEqual(30, board.fields.len);
// }
//
// test "draw" {
//     const a = std.heap.page_allocator;
//     var board = try Board.init(a, 6, 5, 10);
//
//     _ = try board.draw();
//
//     try testing.expect(true);
// }
//
//}}}

test "getSurrounding -> case 0 -> len 3" { // {{{
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    const s = try board.getSurrounding(0);

    try testing.expectEqual(s.len, 3);
}

test "getSurrounding -> case w - 1 -> len 3" {
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    const s = try board.getSurrounding(5);

    try testing.expectEqual(s.len, 3);
}

test "getSurrounding -> case w * (h - 1) -> len 3" {
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    const s = try board.getSurrounding(6 * 4);

    try testing.expectEqual(s.len, 3);
}

test "getSurrounding -> case len - 1 -> len 3" {
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    const s = try board.getSurrounding(29);

    try testing.expectEqual(s.len, 3);
} // }}}

test "getSurrounding -> case 1 -> len 5" { // {{{
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    const s = try board.getSurrounding(1);

    try testing.expectEqual(s.len, 5);
}

test "getSurrounding -> case len - 2 -> len 5" {
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    const s = try board.getSurrounding(28);

    try testing.expectEqual(s.len, 5);
} // }}}

test "getSurrounding -> case len - 2 - h -> len 8" { // {{{
    const a = std.heap.page_allocator;
    var board = try Board.init(a, 6, 5, 10);

    const s = try board.getSurrounding(22);

    try testing.expectEqual(s.len, 8);
} // }}}
