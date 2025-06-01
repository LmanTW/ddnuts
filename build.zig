const std = @import("std");

const release_targets = @as([]const std.Target.Query, &.{
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },

    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },

    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .windows }
});

// Build the project.
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    addRunStep(b, target, optimize);

    for (release_targets) |release_target| {
        const exe = b.addExecutable(.{
            .name = "ddnuts",
            .root_source_file = b.path("./src/main.zig"),

            .target = b.resolveTargetQuery(release_target),
            .optimize = .ReleaseSafe,

            .strip = true
        }); 

        const os_name = @tagName(release_target.os_tag.?);
        const arch_name = switch (release_target.cpu_arch.?) {
            .x86_64 => "amd64",
            .aarch64 => "arm64",

            else => @panic("Unsupported Platform")
        };

        const output = b.addInstallArtifact(exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = ""
                }
            },

            .dest_sub_path = switch (release_target.os_tag.?) {
                .linux, .macos => try std.fmt.allocPrint(b.allocator, "ddnuts-{s}-{s}", .{os_name, arch_name}),
                .windows => try std.fmt.allocPrint(b.allocator, "ddnuts-{s}-{s}.exe", .{os_name, arch_name}),

                else => @panic("Unsupported Platform")
            }
        });

        b.getInstallStep().dependOn(&output.step);
    } 
}

// Add the run step.
pub fn addRunStep(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "ddnuts",
        .root_source_file = b.path("./src/main.zig"),
        
        .target = target,
        .optimize = optimize
    });

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the project");
    run_step.dependOn(&run_exe.step);

    if (b.args) |args| {
        run_exe.addArgs(args);
    }

}
