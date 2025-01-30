const std = @import("std");
const Window = @import("engine/window.zig");
const Event = @import("engine/loop.zig").Event;
const Board = @import("board/board.zig").Board;
const Cursor = @import("board/cursor.zig").Cursor;
const Engine = @import("engine/engine.zig");

const Sapex = @This();

const BOARD_W = 8;
const BOARD_H = 6;
const MINE_CNT = 16;

const interval_ns: u64 = 16 * 1_000_000;

pub const GameState = enum {
    on,
    over,
    win,
};

allocator: std.mem.Allocator,
engine: *Engine,
board: Board,
game_state: GameState,
cursor: Cursor,

pub fn init(allocator: std.mem.Allocator, engine: *Engine) !Sapex {
    const board = try Board.init(allocator, BOARD_W, BOARD_H, MINE_CNT);
    return .{
        .allocator = allocator,
        .engine = engine,
        .game_state = .on,
        .board = board,
        .cursor = Cursor.init(board.w, board.h),
    };
}

pub fn deinit(self: *Sapex) void {
    _ = self;
}

fn onEvent(self: *Sapex, event: Event) !void {
    switch (event.key) {
        'q' => {
            self.quit();
        },
        'h' => {
            self.cursor.moveXBy(-1);
        },
        'j' => {
            self.cursor.moveYBy(1);
        },
        'k' => {
            self.cursor.moveYBy(-1);
        },
        'l' => {
            self.cursor.moveXBy(1);
        },
        'f' => {
            if (self.game_state == .on) {
                const pos = self.cursor.getPos();
                const exists = self.board.getField(pos.x, pos.y);
                if (exists) |field| {
                    field.toggleFlag();
                }
            }
        },
        'r' => {
            self.board = try Board.init(self.allocator, BOARD_W, BOARD_H, MINE_CNT);
            self.game_state = .on;
        },
        'd' => {
            if (self.game_state == .on) {
                const pos = self.cursor.getPos();
                const index = try self.board.getPosIndex(pos.x, pos.y);
                const field = self.board.getFieldByIndex(index);

                self.board.expose(index);

                if (field.mine and field.exposed) {
                    self.game_state = .over;
                } else if (self.board.isCompleted()) {
                    self.game_state = .win;
                }
            }
        },
        else => {},
    }
}

pub fn run(self: *Sapex) !void {
    try self.engine.start();

    const window = try self.engine.createWindow(BOARD_W, BOARD_H);

    while (self.engine.isRunning()) {
        // handle user input
        while (self.engine.loop.popEvent()) |user_event| {
            try self.onEvent(user_event);
        }

        const board_buf = try self.board.draw();
        _ = try window.writeBuffer(board_buf);
        const cursor_buf = self.cursor.draw();
        const x = self.cursor.pos.x;
        const y = self.cursor.pos.y;
        if (x >= 0 and y >= 0) {
            _ = try window.writeAt(@as(usize, @intCast(x)), @as(usize, @intCast(y)), try std.fmt.allocPrint(self.allocator, "{s}", .{cursor_buf}));
        }

        try self.engine.write();

        std.time.sleep(interval_ns);
    }
}

pub fn quit(self: *Sapex) void {
    self.engine.quit();
}
