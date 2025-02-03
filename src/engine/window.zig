const std = @import("std");
const ArrayList = std.ArrayList;
const testing = std.testing;
const Event = @import("loop.zig").Event;

const Window = @This();

pub const WindowError = error{
    WindowOutSizeOfParent,
};

const WindowClean = struct {
    self: fn () void,
};

pub const WindowBorder = enum {
    rounded,
    square,
    none,
};

const rounded: [6][]const u8 = .{ "╭", "─", "╮", "│", "╯", "╰" };
const square: [6][]const u8 = .{ "┌", "─", "┐", "│", "┘", "└" };

pub const WindowStyle = struct {
    w: u8 = 0,
    h: u8 = 0,
    off_x: u8 = 0,
    off_y: u8 = 0,
    border: WindowBorder = WindowBorder.none,
};

allocator: std.mem.Allocator,
buf: [1000]u8 = [_]u8{0} ** 1000,
style: WindowStyle = .{},
children: ArrayList(Window),
// clean: WindowClean,

/// shadow window, is not displayed, only contains single target window
pub const ShadowWindow = struct {
    window: Window,

    pub fn init(
        allocator: std.mem.Allocator,
        style: WindowStyle,
    ) ShadowWindow {
        return .{ .window = Window.init(allocator, style) };
    }

    pub fn deinit(self: *ShadowWindow) void {
        self.window.deinit();
    }
};

pub fn init(allocator: std.mem.Allocator, style: WindowStyle) Window {
    return .{ .style = style, .children = ArrayList(Window).init(allocator), .allocator = allocator };
}

pub fn deinit(self: *Window) void {
    // self.clean.self();
    self.children.deinit();
}

pub fn child(self: *Window, style: WindowStyle) !*Window {
    // const new_i = self.children.items.len;
    const parent_bor_w: u8 = switch (self.style.border) {
        .none => 0,
        else => 3,
    };
    const parent_w = self.style.w - parent_bor_w;
    const parent_h = self.style.h - parent_bor_w;

    var ch = Window.init(self.allocator, style);
    const bor_w: u8 = switch (ch.style.border) {
        .none => 0,
        else => 3,
    };
    const ch_w = ch.style.w + ch.style.off_x + bor_w;
    const ch_h = ch.style.h + ch.style.off_y + bor_w;

    if (ch_w > parent_w or ch_h > parent_h) {
        ch.deinit();
        return WindowError.WindowOutSizeOfParent;
    }
    const ptr = try self.children.addOne();
    ptr.* = ch;
    return ptr;
}

pub fn writeBuffer(self: *Window, buf: []u8) !usize {
    const len = buf.len;
    for (0..len) |i| {
        self.buf[i] = buf[i];
    }
    return self.buf.len;
}

pub fn writeAt(self: *Window, x: usize, y: usize, buf: []u8) !usize {
    const idx: usize = y * @as(usize, @intCast(self.style.w)) + x;
    self.buf[idx] = buf[0];
    return idx;
}

pub fn writeSliceAt(self: *Window, x: usize, y: usize, buf: []u8) !usize {
    const idx: usize = y * @as(usize, @intCast(self.style.w)) + x;

    const len = buf.len;

    for (0..len) |i| {
        self.buf[idx + i] = buf[i];
    }
    return idx + len;
}

const testingAllocator = std.testing.allocator;
// fn cleanSelf() void {
//     return;
// }
test "init" {
    {
        var parent = Window.init(testingAllocator, .{});
        defer parent.deinit();

        _ = try testing.expectEqual(parent.style.h, 0);
        _ = try testing.expectEqual(parent.style.w, 0);
    }

    {
        var parent = Window.init(testingAllocator, .{ .w = 12, .h = 12, .off_x = 10, .off_y = 15, .border = .rounded });
        defer parent.deinit();

        _ = try testing.expectEqual(parent.style.h, 12);
        _ = try testing.expectEqual(parent.style.w, 12);
        _ = try testing.expectEqual(parent.style.off_y, 15);
        _ = try testing.expectEqual(parent.style.off_x, 10);
    }
}

test "child" {
    // have provided style
    {
        var parent = Window.init(testingAllocator, .{ .w = 12, .h = 12, .off_x = 10, .off_y = 15, .border = .rounded });
        defer parent.deinit();
        const ch = try parent.child(.{ .w = 4, .h = 4, .off_y = 5, .border = .none });

        _ = try testing.expectEqual(ch.style.h, 4);
        _ = try testing.expectEqual(ch.style.w, 4);
        _ = try testing.expectEqual(ch.style.off_y, 5);
        _ = try testing.expectEqual(ch.style.off_x, 0);
        _ = try testing.expectEqual(ch.style.border, WindowBorder.none);
    }
    // should create new window in bounds of parent
    {
        var parent = Window.init(testingAllocator, .{ .w = 12, .h = 12, .off_x = 10, .off_y = 15, .border = .rounded });
        defer parent.deinit();
        _ = try testing.expectError(WindowError.WindowOutSizeOfParent, parent.child(.{ .w = 13 }));
        _ = try testing.expectError(WindowError.WindowOutSizeOfParent, parent.child(.{ .h = 13 }));
        _ = try testing.expectError(WindowError.WindowOutSizeOfParent, parent.child(.{ .w = 1, .off_x = 12 }));
        _ = try testing.expectError(WindowError.WindowOutSizeOfParent, parent.child(.{ .h = 1, .off_y = 15 }));
        _ = try testing.expectError(WindowError.WindowOutSizeOfParent, parent.child(.{ .w = 1, .off_x = 10, .border = .rounded }));
        _ = try testing.expectError(WindowError.WindowOutSizeOfParent, parent.child(.{ .h = 1, .off_y = 10, .border = .square }));
        _ = try parent.child(.{ .h = 1, .off_y = 1, .border = .square });
    }
}

// TODO write render function that includes childwindow in output
// test "render" {}
