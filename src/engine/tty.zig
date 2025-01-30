const std = @import("std");
const posix = std.posix;

const Tty = @This();

pub const sync_set = "\x1b[?2026h";
pub const sync_reset = "\x1b[?2026l";
pub const clean = "\x1b[2J";
pub const clear = "\x1b[1;1H\x1b[2J";
// pub const clear = "\x1b[1;1H";

// Cursor
pub const home = "\x1b[H";
pub const cup = "\x1b[{d};{d}H";
pub const hide_cursor = "\x1b[?25l";
pub const show_cursor = "\x1b[?25h";
pub const cursor_shape = "\x1b[{d} q";
pub const ri = "\x1bM";
pub const ind = "\n";
pub const cuu = "\x1b[{d}A";
pub const cud = "\x1b[{d}B";
pub const cur = "\x1b[{d}C";
pub const cul = "\x1b[{d}D";
pub const cue = "\x1b[{d}E";

fd: posix.fd_t,
restore_tty: posix.termios,

pub const Winsize = struct {
    rows: u16,
    cols: u16,
    x_pixel: u16,
    y_pixel: u16,
};

pub fn init() !Tty {
    const fd = try posix.open("/dev/tty", .{ .ACCMODE = .RDWR }, 0);
    const termios = try makeRaw(fd);
    return .{ .fd = fd, .restore_tty = termios };
}

pub fn deinit(self: *Tty) void {
    posix.tcsetattr(self.fd, .FLUSH, self.restore_tty) catch |err| {
        std.log.err("couldn't restore terminal: {}", .{err});
    };
    posix.close(self.fd);
}

pub fn read(self: *Tty, buf: []u8) !usize {
    return try posix.read(self.fd, buf);
}

pub fn write(self: *Tty, buf: []const u8) !usize {
    return try posix.write(self.fd, buf);
}

fn opaqueWrite(ptr: *const anyopaque, bytes: []const u8) !usize {
    const self: *const Tty = @ptrCast(@alignCast(ptr));
    return posix.write(self.fd, bytes);
}

pub fn getWriter(self: *Tty) std.io.AnyWriter {
    return .{ .context = self, .writeFn = opaqueWrite };
}

/// Get the window size from the kernel
pub fn getWinsize(self: *Tty) !Winsize {
    var winsize = posix.winsize{
        .ws_row = 0,
        .ws_col = 0,
        .ws_xpixel = 0,
        .ws_ypixel = 0,
    };

    const err = posix.system.ioctl(self.fd, posix.T.IOCGWINSZ, @intFromPtr(&winsize));
    if (posix.errno(err) == .SUCCESS)
        return Winsize{
            .rows = winsize.ws_row,
            .cols = winsize.ws_col,
            .x_pixel = winsize.ws_xpixel,
            .y_pixel = winsize.ws_ypixel,
        };
    return error.IoctlError;
}

/// makeRaw enters the raw state for the terminal.
fn makeRaw(fd: posix.fd_t) !posix.termios {
    const state = try posix.tcgetattr(fd);
    var raw = state;

    // see termios(3)
    raw.iflag.IGNBRK = true;
    raw.iflag.BRKINT = false;
    raw.iflag.PARMRK = false;
    raw.iflag.ISTRIP = false;
    raw.iflag.INLCR = false;
    raw.iflag.IGNCR = false;
    raw.iflag.ICRNL = false;
    raw.iflag.IXON = false;

    raw.oflag.OPOST = false;

    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    raw.lflag.ECHONL = false;
    raw.lflag.ISIG = true;
    raw.lflag.IEXTEN = false;

    raw.cflag.CSIZE = .CS8;
    raw.cflag.PARENB = false;

    raw.cc[@intFromEnum(posix.V.MIN)] = 1;
    raw.cc[@intFromEnum(posix.V.TIME)] = 0;
    try posix.tcsetattr(fd, .FLUSH, raw);
    return state;
}
