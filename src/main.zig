const builtin = @import("builtin");
const std = @import("std");

const Interface = @import("./Interface.zig");
const Updater = @import("./Updater.zig");
const Config = @import("./Config.zig");

// The main function :3
pub fn main() !void {
    var debug = std.heap.DebugAllocator(.{}).init;
    defer _ = debug.deinit();
 
    // Yes sir, your allocator.
    const allocator = debug.allocator();

    var interface = try Interface.init(allocator);
    defer interface.deinit();

    if (interface.countArguments() > 0 and std.mem.eql(u8, interface.getArgument(0), "help")) {
        interface.write(
            \\A lightweight tool for updating Cloudflare DNS records (DDNS).
            \\
            \\Usage:
            \\  ddnuts [...options]
            \\  ddnuts <domain> [...options]
            \\
            \\Options:
            \\  config=<path>           The path to the config file.
            \\
            \\  - Providing the options below will override the global options.
            \\  - See the config file for more detail.
            \\
            \\  zone_id=<zone-id>       The zone where the domain belongs to.
            \\  api_token=<api-token>   Your API Token that have access to the zone.
            \\  interval=<interval>     The interval between each update.
            \\
        );

        return; 
    }

    var updaters: []Updater = undefined;
    defer {
        for (updaters) |*updater| {
            updater.deinit();
        }

        allocator.free(updaters);
    }

    if (interface.countArguments() > 0) {
        updaters = try allocator.alloc(Updater, interface.countArguments());

        for (0..interface.countArguments()) |index| {
            updaters[index] = try Updater.init(interface.getArgument(index), .{
                .zone_id = interface.getOption("zone_id"),
                .api_token = interface.getOption("api_token"),
                .interval = Config.parseInterval(interface.getOptionDefault("interval", "10s")) catch 10 * std.time.ms_per_min
            }, allocator);
        }
    } else {
        var config = try loadConfig(&interface, allocator);
        defer config.deinit();

        if (interface.getOption("zone_id")) |zone_id|
            try Config.updateOption(&config.global.zone_id, zone_id, allocator);
        if (interface.getOption("api_token")) |api_token|
            try Config.updateOption(&config.global.api_token, api_token, allocator);
        if (interface.getOption("interval")) |interval|
            config.global.interval = Config.parseInterval(interval) catch config.global.interval;

        updaters = try allocator.alloc(Updater, config.domains.count());

        var domain_iterator = config.domains.iterator();
        var index: u8 = 0;

        while (domain_iterator.next()) |entry| {
            updaters[index] = try Updater.init(entry.key_ptr.*, .{
                .zone_id = entry.value_ptr.zone_id orelse config.global.zone_id,
                .api_token = entry.value_ptr.api_token orelse config.global.api_token,
                .interval = entry.value_ptr.interval orelse config.global.interval
            }, allocator);

            index += 1;
        }
    }

    while (true) {
        for (updaters) |*updater| {
            updater.update(&interface) catch {
                interface.log(.Error, "Failed to update \"{s}\" because of an unknown error", .{updater.domain});
            };
        }

        std.Thread.sleep(std.time.ns_per_s);
    }
}

// Load the config.
fn loadConfig (interface: *Interface, allocator: std.mem.Allocator) !Config {
    const cwd_path = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd_path);

    var config_path: []const u8 = undefined;
    defer allocator.free(config_path);

    if (interface.getOption("config")) |config| {
        config_path = try std.fs.path.resolve(allocator, &.{cwd_path, config});
    } else {
        config_path = try std.fs.path.resolve(allocator, &.{cwd_path, "./ddnuts.conf"});
    }
    
    interface.log(.Running, "Loading the config: \"{s}\"", .{config_path});
    interface.log(.Progress, "Reading the config...", .{});

    std.fs.accessAbsolute(config_path, .{}) catch {
        interface.log(.Progress, "Config not found, creating one...", .{});

        const file = try std.fs.createFileAbsolute(config_path, .{});
        defer file.close();

        try file.writeAll(
            \\# To add a domain to update, specify the domain and options:
            \\#
            \\# [ <domain> ]
            \\# zone_id = ...
            \\# api_token = ...
            \\# interval = ...
            \\#
            \\# You can also set global options by putting them before any domain:
            \\#
            \\# zone_id = ...
            \\# api_token = ...
            \\#
            \\# [ <domain> ]
            \\# zone_id = ...
            \\# api_token = ...
            \\
            \\# <zone_id> (Required)
            \\# The zone where the domain belongs to.
            \\#
            \\# <api_token> (Required)
            \\# Your API Token that have access to the zone.
            \\#
            \\# <interval> (Default to 10 minutes)
            \\# The interval between each update. Default to using ms, but other units are also supported: 1s (seconds), 1m (minutes), 1h (hours)
        );
    };

    const file = try std.fs.openFileAbsolute(config_path, .{});
    defer file.close();

    const buffer = try allocator.alloc(u8, try file.getEndPos());
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    interface.log(.Progress, "Parsing the config...", .{});

    const config = Config.init(buffer, allocator) catch {
        interface.log(.Error, "Failed to parse the config", .{});

        return error.Failed;
    };

    interface.log(.Complete, "Successfulyl loaded the config!", .{});

    return config;
}
