const builtin = @import("builtin");
const std = @import("std");

const Config = @This();

allocator: std.mem.Allocator,

global: Options,
domains: std.StringHashMap(Options),

// The options.
pub const Options = struct {
    zone_id: ?[]const u8 = null,
    api_token: ?[]const u8 = null,
    interval: ?u32 = null
};

// Initialize a config.
pub fn init(buffer: []const u8, allocator: std.mem.Allocator) !Config {
    var domains = std.StringHashMap(Options).init(allocator);
    errdefer {
        var domain_iterator = domains.iterator();

        while (domain_iterator.next()) |entry| {
            allocator.free(entry.key_ptr.*);

            if (entry.value_ptr.zone_id) |zone_id|
                allocator.free(zone_id);
            if (entry.value_ptr.api_token) |api_token|
                allocator.free(api_token);
        }

        domains.deinit();
    }

    var global_options = Options{};
    errdefer {
        if (global_options.zone_id) |zone_id|
            allocator.free(zone_id);
        if (global_options.api_token) |api_token|
            allocator.free(api_token);
    }

    var line_iterator = std.mem.splitScalar(u8, buffer, '\n');
    var current_domain: ?[]const u8 = null;

    while (line_iterator.next()) |line| {
        const trimed_line = std.mem.trim(u8, line, " ");

        if (trimed_line.len > 0 and trimed_line[0] != '#') {
            if (trimed_line[0] == '[' and trimed_line[trimed_line.len - 1] == ']') {
                const domain_name = std.mem.trim(u8, trimed_line[1..trimed_line.len - 1], " ");

                if (domains.get(domain_name) == null) {
                    current_domain = try allocator.dupe(u8, domain_name);
                    errdefer allocator.free(current_domain.?);

                    try domains.put(current_domain.?, .{});
                }
            } else if (std.mem.indexOfScalar(u8, trimed_line, '=')) |separator_index| {
                const name = std.mem.trim(u8, trimed_line[0..separator_index], " ");
                const value = std.mem.trim(u8, trimed_line[separator_index + 1..], " ");

                if (current_domain) |domain| {
                    var domain_options = domains.getEntry(domain).?;

                    if (std.mem.eql(u8, name, "zone_id"))
                        try updateOption(&domain_options.value_ptr.zone_id, value, allocator);
                    if (std.mem.eql(u8, name, "api_token"))
                        try updateOption(&domain_options.value_ptr.api_token, value, allocator);
                    if (std.mem.eql(u8, name, "interval"))
                        domain_options.value_ptr.interval = parseInterval(value) catch domain_options.value_ptr.interval;
                } else {
                    if (std.mem.eql(u8, name, "zone_id"))
                        try updateOption(&global_options.zone_id, value, allocator);
                    if (std.mem.eql(u8, name, "api_token"))
                        try updateOption(&global_options.api_token, value, allocator);
                    if (std.mem.eql(u8, name, "interval"))
                        global_options.interval = parseInterval(value) catch global_options.interval;
                }
            }
        }
    }
    
    return Config{
        .allocator = allocator,

        .global = global_options,
        .domains = domains
    };
}

// Deinitialize the config.
pub fn deinit(self: *Config) void {
    if (self.global.zone_id) |zone_id|
        self.allocator.free(zone_id);
    if (self.global.api_token) |api_token|
        self.allocator.free(api_token);

    var domain_iterator = self.domains.iterator();

    while (domain_iterator.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
        
        if (entry.value_ptr.zone_id) |zone_id|
            self.allocator.free(zone_id);
        if (entry.value_ptr.api_token) |api_token|
            self.allocator.free(api_token);
    }

    self.domains.deinit();
}

// Update an option.
pub fn updateOption (current: *?[]const u8, value: []const u8, allocator: std.mem.Allocator) !void {
    if (current.*) |buffer| {
        allocator.free(buffer);
    }

    current.* = try allocator.dupe(u8, value);
}

// Parse the interval.
pub fn parseInterval(interval: []const u8) !u32 {
    return switch (interval[interval.len - 1]) {
        's' => try std.fmt.parseInt(u32, interval[0..interval.len - 1], 10) * std.time.ms_per_s,
        'm' => try std.fmt.parseInt(u32, interval[0..interval.len - 1], 10) * std.time.ms_per_min,
        'h' => try std.fmt.parseInt(u32, interval[0..interval.len - 1], 10) * std.time.ms_per_hour,

        else => try std.fmt.parseInt(u32, interval, 10)
    };
}
