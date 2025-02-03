const std = @import("std");
const Engine = @import("engine/engine.zig");
const Tty = @import("engine/tty.zig");
const Loop = @import("engine/loop.zig");
const Sapex = @import("sapex.zig");
const Board = @import("board/board.zig").Board;
const Cursor = @import("board/cursor.zig").Cursor;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) {
            std.log.err("memory leak", .{});
        }
    }
    const allocator = gpa.allocator();

    var tty = try Tty.init();
    defer tty.deinit();
    var engine = try Engine.init(allocator, &tty);
    defer engine.deinit();

    var sapex = try Sapex.init(allocator, &engine);
    defer sapex.deinit();

    try sapex.run();
    return;
}
