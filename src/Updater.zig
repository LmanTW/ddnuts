const std = @import("std");

const Interface = @import("./Interface.zig");
const network = @import("./network.zig");
const Config = @import("./Config.zig");

const Updater = @This();

allocator: std.mem.Allocator,
last_update: ?i64,

domain: []const u8,
zone_id: ?[]const u8,
api_token: ?[]const u8,
interval: u32,

// Initialize an updater.
pub fn init(domain: []const u8, options: Config.Options, allocator: std.mem.Allocator) !Updater {
    return Updater{
        .allocator = allocator,
        .last_update = null,

        .domain = try allocator.dupe(u8, domain),
        .zone_id = if (options.zone_id) |zone_id| try allocator.dupe(u8, zone_id) else null,
        .api_token = if (options.api_token) |api_token| try allocator.dupe(u8, api_token) else null,
        .interval = options.interval orelse 10 * std.time.ms_per_min
    };
}

// Deinitialize the updater.
pub fn deinit(self: *Updater) void {
    self.allocator.free(self.domain);
    
    if (self.zone_id) |zone_id|
        self.allocator.free(zone_id);
    if (self.api_token) |api_token|
        self.allocator.free(api_token);
}

// Update the domain.
pub fn update(self: *Updater, interface: *Interface) !void {
    if (self.last_update == null or std.time.milliTimestamp() - self.last_update.? > self.interval) {
        self.last_update = std.time.milliTimestamp();

        if (self.zone_id == null or self.api_token == null) {
            if (self.zone_id == null and self.api_token == null) {
                interface.log(.Info, "Skipping \"{s}\" because <zone_id> and <api_token> are missing", .{self.domain});
            } else if (self.zone_id == null) {
                interface.log(.Info, "Skipping \"{s}\" because <zone_id> is missing", .{self.domain});
            } else if (self.api_token == null) {
                interface.log(.Info, "Skipping \"{s}\" because <api_token> is missing", .{self.domain});
            }
        } else {
            interface.log(.Running, "Updating: \"{s}\"", .{self.domain});
            interface.log(.Progress, "Listing the records...", .{});

            const record_list_url = try std.fmt.allocPrint(self.allocator, "https://api.cloudflare.com/client/v4/zones/{s}/dns_records?name={s}", .{self.zone_id.?, self.domain});
            defer self.allocator.free(record_list_url);

            const record_list_response = try network.sendRequestAPI(.GET, record_list_url, self.api_token.?, null, self.allocator);
            defer self.allocator.free(record_list_response.body); 

            const record_list = try std.json.parseFromSlice(Response, self.allocator, record_list_response.body, .{ .ignore_unknown_fields = true });
            defer record_list.deinit();

            if (!record_list.value.success) {
                interface.log(.Error, "Failed to list the records: \"{s}\"", .{record_list.value.errors[0].message});

                return;
            }
            
            const record_list_result = try std.json.parseFromSlice(RecordList, self.allocator, record_list_response.body, .{ .ignore_unknown_fields = true });
            defer record_list_result.deinit();

            interface.log(.Progress, "Updating the records...", .{});

            const public_ip_response = try network.sendRequest(.GET, "https://myip.wtf/text", .{}, null, self.allocator);
            defer self.allocator.free(public_ip_response.body);

            if (public_ip_response.status != .ok) {
                interface.log(.Error, "Failed to get the public IP: \"https://myip.wtf/text\" ({})", .{@intFromEnum(public_ip_response.status)});

                return;
            }

            var success: u8 = 0;
            var failed: u8 = 0;

            for (record_list_result.value.result) |record| {
                if (std.mem.eql(u8, record.type, "A") and !std.mem.eql(u8, record.content, public_ip_response.body)) {
                    const record_update_url= try std.fmt.allocPrint(self.allocator, "https://api.cloudflare.com/client/v4/zones/{s}/dns_records/{s}", .{self.zone_id.?, record.id});
                    defer self.allocator.free(record_update_url);

                    const record_update_payload = try std.json.stringifyAlloc(self.allocator, .{
                        .type = "A",
                        .name = self.domain,
                        .content = public_ip_response.body
                    }, .{});
                    defer self.allocator.free(record_update_payload);

                    const record_update_response = try network.sendRequestAPI(.PUT, record_update_url, self.api_token.?, record_update_payload, self.allocator);
                    defer self.allocator.free(record_update_response.body);

                    const record_update = try std.json.parseFromSlice(Response, self.allocator, record_list_response.body, .{ .ignore_unknown_fields = true });
                    defer record_update.deinit();

                    if (record_list.value.success) {
                        success += 1;
                    } else {
                        interface.log(.Warning, "Failed to update the record: \"{s}\"", .{record_update.value.errors[0].message});

                        failed += 1;
                    }
                }
            }

            if (success == 0 and failed == 0) {
                interface.log(.Complete, "Nothing changed, none of the records are updated!", .{});
            } else {
                interface.log(.Complete, "Successfulyl updated {} records, {} failed.", .{success, failed});
            }
        }
    }
}

// The response.
const Response = struct {
    success: bool,
    errors: []Error
};

// The record list result.
const RecordList = struct {
    result: []struct {
        id: []const u8,
        type: []const u8,
        content: []const u8
    }
};

// The error.
const Error = struct {
    message: []const u8,
};
