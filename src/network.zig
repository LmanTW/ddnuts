const std = @import("std");

// Send a HTTP request.
pub fn sendRequest(method: std.http.Method, url: []const u8, headers: std.http.Client.Request.Headers, payload: ?[]const u8, allocator: std.mem.Allocator) !Response {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit(); 

    var response_storage = std.ArrayList(u8).init(allocator);
    errdefer response_storage.deinit();

    const response = try client.fetch(.{
        .method = method,

        .location = .{
            .url = url,
        },

        .headers = headers,
        .payload = payload,

        .response_storage = .{ .dynamic = &response_storage },
        .max_append_size = std.math.maxInt(u32)
    });

    return Response{
        .status = response.status,
        .body = try response_storage.toOwnedSlice()
    };
}

// Send a CloudFlare API Request.
pub fn sendRequestAPI(method: std.http.Method, url: []const u8, token: []const u8, payload: ?[]const u8, allocator: std.mem.Allocator) !Response {
    const token_buffer = try std.fmt.allocPrint(allocator, "Bearer {s}", .{token});
    defer allocator.free(token_buffer);

    return try sendRequest(method, url, .{
        .content_type = .{ .override = "application/json" },
        .authorization = .{ .override = token_buffer }
    }, payload, allocator);
}

// The response.
const Response = struct {
    status: std.http.Status,
    body: []u8
};
