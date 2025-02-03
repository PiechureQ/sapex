const std = @import("std");
const Loop = @import("loop.zig");
const Tty = @import("tty.zig");
const Window = @import("window.zig");
const ShadowWindow = @import("window.zig").ShadowWindow;

const Engine = @This();

pub const EngineError = error{NoMainWindow};

allocator: std.mem.Allocator,
should_quit: bool = false,
loop: Loop,
tty: *Tty,
sw: ShadowWindow,

pub fn init(allocator: std.mem.Allocator, tty: *Tty) !Engine {
    const loop = try Loop.init(allocator, tty);
    return .{ .allocator = allocator, .tty = tty, .loop = loop, .sw = ShadowWindow.init(allocator, .{ .w = 1, .h = 1 }) };
}

pub fn deinit(self: *Engine) void {
    self.loop.deinit();
    self.sw.deinit();
    self.loop.stop();
}

pub fn getWinsize(self: *Engine) !Tty.Winsize {
    const winsize = try self.tty.getWinsize();
    return winsize;
}

pub fn createWindow(self: *Engine, w: u16, h: u16) *Window {
    self.sw = ShadowWindow.init(self.allocator, .{ .w = @intCast(w), .h = @intCast(h) });
    return &self.sw.window;
}

pub fn getWindow(self: *Engine) *Window {
    return &self.sw.window;
}

pub fn start(
    self: *Engine,
) !void {
    try self.loop.start();

    const tty = self.tty.getWriter();
    try tty.writeAll(Tty.clear);
}

pub fn write(self: *Engine) !void {
    const win = self.getWindow();
    const tty = self.tty.getWriter();
    try tty.writeAll(Tty.home);

    var col: usize = 0;
    var row: usize = 0;
    const win_size = win.style.w * win.style.h;
    for (0..win_size) |i| {
        row += 1;
        if (row >= win.style.w) {
            col += 1;
            row = 0;
        }

        const char = win.buf[i .. i + 1];
        _ = try tty.print("{s}", .{char});
        try tty.print(Tty.cup, .{ col + 1, row + 1 });
    }
}

pub fn isRunning(self: *Engine) bool {
    return !self.should_quit;
}

// TODO quit nie dziala od razu, poniewaz odpala sie Tty.read jeszcze zamin petla sie przerwie
pub fn quit(self: *Engine) void {
    self.should_quit = true;
    // self.loop.stop();
}
