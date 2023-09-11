const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zig_tracy = b.anonymousDependency(
        "./libs/zig-tracy",
        @import("libs/zig-tracy/build.zig"),
        .{
            .target = target,
            .optimize = optimize,
        }
    );

    const exe = b.addExecutable(.{
        .name = "tracy-example",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("tracy", zig_tracy.module("tracy"));
    exe.linkLibrary(zig_tracy.artifact("tracy"));
    exe.linkLibCpp();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
