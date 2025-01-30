const std = @import("std");
const Event = @import("loop.zig").Event;

const Window = @This();

buf: []u8,
w: u8,
h: u8,
size: usize,

var on_event: ?*const fn (event: Event) void = null;

fn createDef(allocator: std.mem.Allocator, w: u16, h: u16) ![]u8 {
    const buffer = try allocator.alloc(u8, @intCast(w * h));
    for (buffer) |*ch| {
        ch.* = ' ';
    }
    return buffer;
}

pub fn init(allocator: std.mem.Allocator, w: u16, h: u16) !Window {
    return .{ .w = @intCast(w), .h = @intCast(h), .size = @intCast(w * h), .buf = try createDef(allocator, w, h) };
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
