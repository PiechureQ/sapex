const std = @import("std");
const Event = @import("loop.zig").Event;

const Window = @This();

allocator: std.mem.Allocator,
buf: [1000]u8 = [_]u8{0} ** 1000,
w: u8,
h: u8,
size: usize,

var on_event: ?*const fn (event: Event) void = null;

pub fn init(allocator: std.mem.Allocator, w: u16, h: u16) !Window {
    return .{ .w = @intCast(w), .h = @intCast(h), .size = @intCast(w * h), .allocator = allocator };
}

pub fn deinit(self: *Window) void {
    _ = self;
    // self.allocator.free(self.buf);
}

pub fn writeBuffer(self: *Window, buf: []u8) !usize {
    const len = buf.len;
    for (0..len) |i| {
        self.buf[i] = buf[i];
    }
    return self.buf.len;
}

pub fn writeAt(self: *Window, x: usize, y: usize, buf: []u8) !usize {
    const idx: usize = y * @as(usize, @intCast(self.w)) + x;
    self.buf[idx] = buf[0];
    return idx;
}

pub fn writeSliceAt(self: *Window, x: usize, y: usize, buf: []u8) !usize {
    const idx: usize = y * @as(usize, @intCast(self.w)) + x;

    const len = buf.len;

    for (0..len) |i| {
        self.buf[idx + i] = buf[i];
    }
    return idx + len;
}

fn write(self: *Window, buf: []u8) !usize {
    return try self.file.write(buf);
}

pub fn clear(self: *Window) !usize {
    return try self.file.write("\x1b[2J");
}
