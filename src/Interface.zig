const std = @import("std");

const Interface = @This();

allocator: std.mem.Allocator,
stdout: std.fs.File.Writer,

args: [][]const u8,
opts: std.BufMap,

// Initialize an interface,
pub fn init(allocator: std.mem.Allocator) !Interface {
    var arg_iterator = try std.process.argsWithAllocator(allocator);
    defer arg_iterator.deinit();

    // Skip the executable itself.
    _ = arg_iterator.skip();

    var args = std.ArrayList([]const u8).init(allocator);
    var opts = std.BufMap.init(allocator);
    errdefer {
        for (args.items) |arg| {
            allocator.free(arg);
        }

        args.deinit();
        opts.deinit();
    }

    while (arg_iterator.next()) |arg| {
        if (std.mem.indexOfScalar(u8, arg, '=')) |separator_index| {
            try opts.put(arg[0..separator_index], arg[separator_index + 1..]);
        } else { 
            const arg_buffer = try allocator.dupe(u8, arg);
            errdefer allocator.free(arg_buffer);

            try args.append(arg_buffer);
        }
    }

    return Interface{
        .allocator = allocator,
        .stdout = std.io.getStdOut().writer(),

        .args = try args.toOwnedSlice(),
        .opts = opts
    };
}

// Deinitialize the interface,
pub fn deinit(self: *Interface) void {
    self.opts.deinit();

    for (self.args) |arg| {
        self.allocator.free(arg);
    }

    self.allocator.free(self.args);
}

// Get an argument.
pub fn getArgument(self: *Interface, index: usize) []const u8 {
    return self.args[index];
}

// Count the arguments.
pub fn countArguments(self: *Interface) usize {
    return self.args.len;
}

// Get an option.
pub fn getOption(self: *Interface, name: []const u8) ?[]const u8 {
    return self.opts.get(name);
}

// Get an option with a default value.
pub fn getOptionDefault(self: *Interface, name: []const u8, default: []const u8) []const u8 {
    return self.opts.get(name) orelse default;
}

// Write something to stdout.
pub fn write(self: *Interface, buffer: []const u8) void {
    _ = self.stdout.write(buffer) catch {};
}

// Print something to stdout.
pub fn print(self: *Interface, comptime fmt: []const u8, args: anytype) void {
    self.stdout.print(fmt, args) catch {};
}

// Log something.
pub fn log(self: *Interface, kind: LogKind, comptime fmt: []const u8, args: anytype) void {
    const content = std.fmt.allocPrint(self.allocator, fmt, args) catch return;
    defer self.allocator.free(content);

    switch (kind) {
        .Info =>     self.print("\x1B[35m[ Info     ]: {s}\x1B[0m\n", .{content}),
        .Warning =>  self.print("\x1B[33m[ Warning  ]: {s}\x1B[0m\n", .{content}),
        .Error =>    self.print("\x1B[31m[ Error    ]: {s}\x1B[0m\n", .{content}),

        .Running =>  self.print("\x1B[39m[ Running  ]: {s}\x1B[0m\n", .{content}),
        .Progress => self.print("\x1B[90m[ Progress ]: {s}\x1B[0m\n", .{content}),
        .Complete => self.print("\x1B[32m[ Complete ]: {s}\x1B[0m\n", .{content})
    }
}

// The kind of the log.
pub const LogKind = enum(u4) {
    Running,
    Progress,
    Complete,

    Info,
    Warning,
    Error
};
