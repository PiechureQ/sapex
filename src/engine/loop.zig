const std = @import("std");
const ArrayList = std.ArrayList;
const Tty = @import("tty.zig");

const Loop = @This();

allocator: std.mem.Allocator,
thread: ?std.Thread = null,

should_quit: bool = false,
queue: ArrayList(Event),
tty: *Tty,

const interval_ns: u64 = 1000 * 1_000_000;

pub fn init(allocator: std.mem.Allocator, tty: *Tty) !Loop {
    return .{ .allocator = allocator, .tty = tty, .queue = ArrayList(Event).init(allocator) };
}

pub fn deinit(self: *Loop) void {
    self.stop();
    self.tty.deinit();
    self.queue.clearAndFree();
}

/// Start new thread and read input in it.
pub fn start(self: *Loop) !void {
    self.thread = try std.Thread.spawn(.{ .allocator = self.allocator }, Loop.readInput, .{self});
}

pub fn stop(self: *Loop) void {
    self.should_quit = true;
    if (self.thread) |th| {
        th.join();
        self.thread = null;
    }
}

pub const Event = struct {
    key: u8,
};

fn parseEvent(buf: []u8) ?Event {
    if (buf.len > 0) {
        return Event{ .key = buf[0] };
    }
    return null;
}

fn readInput(self: *Loop) !void {
    while (!self.should_quit) {
        var buf: [1024]u8 = undefined;
        const len = self.tty.read(&buf) catch |err| {
            std.debug.print("{}\n", .{err});
            continue;
        };

        const input = buf[0..len];

        const parsed = parseEvent(input);
        if (parsed) |event| {
            self.pushEvent(event);
        }

        // if (std.mem.eql(u8, input, "q")) {
        //     self.quit();
        //     break;
        // }
    }
}

fn pushEvent(self: *Loop, ev: Event) void {
    self.queue.append(ev) catch |err| {
        std.debug.print("loop pushEvent: {}", .{err});
    };
}

pub fn popEvent(self: *Loop) ?Event {
    if (self.queue.items.len > 0) {
        return self.queue.popOrNull();
    } else {
        return null;
    }
}
