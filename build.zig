const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tracy_enable = b.option(bool, "tracy_enable", "Enable profiling") orelse true;
    const tracy_on_demand = b.option(bool, "tracy_on_demand", "On-demand profiling") orelse false;
    const tracy_callstack: ?u8 = b.option(u8, "tracy_callstack", "Enforce callstack collection for tracy regions");
    const tracy_no_callstack = b.option(bool, "tracy_no_callstack", "Disable all callstack related functionality") orelse false;
    const tracy_no_callstack_inlines = b.option(bool, "tracy_no_callstack_inlines", "Disables the inline functions in callstacks") orelse false;
    const tracy_only_localhost = b.option(bool, "tracy_only_localhost", "Only listen on the localhost interface") orelse false;
    const tracy_no_broadcast = b.option(bool, "tracy_no_broadcast", "Disable client discovery by broadcast to local network") orelse false;
    const tracy_only_ipv4 = b.option(bool, "tracy_only_ipv4", "Tracy will only accept connections on IPv4 addresses (disable IPv6)") orelse false;
    const tracy_no_code_transfer = b.option(bool, "tracy_no_code_transfer", "Disable collection of source code") orelse false;
    const tracy_no_context_switch = b.option(bool, "tracy_no_context_switch", "Disable capture of context switches") orelse false;
    const tracy_no_exit = b.option(bool, "tracy_no_exit", "Client executable does not exit until all profile data is sent to server") orelse false;
    const tracy_no_sampling = b.option(bool, "tracy_no_sampling", "Disable call stack sampling") orelse false;
    const tracy_no_verify = b.option(bool, "tracy_no_verify", "Disable zone validation for C API") orelse false;
    const tracy_no_vsync_capture = b.option(bool, "tracy_no_vsync_capture", "Disable capture of hardware Vsync events") orelse false;
    const tracy_no_frame_image = b.option(bool, "tracy_no_frame_image", "Disable the frame image support and its thread") orelse false;
    // NOTE For some reason system tracing on zig projects crashes tracy, will need to investigate
    const tracy_no_system_tracing = b.option(bool, "tracy_no_system_tracing", "Disable systrace sampling") orelse true;
    const tracy_delayed_init = b.option(bool, "tracy_delayed_init", "Enable delayed initialization of the library (init on first call)") orelse false;
    const tracy_manual_lifetime = b.option(bool, "tracy_manual_lifetime", "Enable the manual lifetime management of the profile") orelse false;
    const tracy_fibers = b.option(bool, "tracy_fibers", "Enable fibers support") orelse false;
    const tracy_no_crash_handler = b.option(bool, "tracy_no_crash_handler", "Disable crash handling") orelse false;
    const tracy_timer_fallback = b.option(bool, "tracy_timer_fallback", "Use lower resolution timers") orelse false;
    const shared = b.option(bool, "shared", "Build the tracy client as a shared libary") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "tracy_enable", tracy_enable);
    options.addOption(bool, "tracy_on_demand", tracy_on_demand);
    options.addOption(?u8, "tracy_callstack", tracy_callstack);
    options.addOption(bool, "tracy_no_callstack", tracy_no_callstack);
    options.addOption(bool, "tracy_no_callstack_inlines", tracy_no_callstack_inlines);
    options.addOption(bool, "tracy_only_localhost", tracy_only_localhost);
    options.addOption(bool, "tracy_no_broadcast", tracy_no_broadcast);
    options.addOption(bool, "tracy_only_ipv4", tracy_only_ipv4);
    options.addOption(bool, "tracy_no_code_transfer", tracy_no_code_transfer);
    options.addOption(bool, "tracy_no_context_switch", tracy_no_context_switch);
    options.addOption(bool, "tracy_no_exit", tracy_no_exit);
    options.addOption(bool, "tracy_no_sampling", tracy_no_sampling);
    options.addOption(bool, "tracy_no_verify", tracy_no_verify);
    options.addOption(bool, "tracy_no_vsync_capture", tracy_no_vsync_capture);
    options.addOption(bool, "tracy_no_frame_image", tracy_no_frame_image);
    options.addOption(bool, "tracy_no_system_tracing", tracy_no_system_tracing);
    options.addOption(bool, "tracy_delayed_init", tracy_delayed_init);
    options.addOption(bool, "tracy_manual_lifetime", tracy_manual_lifetime);
    options.addOption(bool, "tracy_fibers", tracy_fibers);
    options.addOption(bool, "tracy_no_crash_handler", tracy_no_crash_handler);
    options.addOption(bool, "tracy_timer_fallback", tracy_timer_fallback);
    options.addOption(bool, "shared", shared);

    const tracy_src = b.dependency("tracy_src", .{});

    const tracy_module = b.addModule("tracy", .{
        .root_source_file = b.path("./src/tracy.zig"),
        .imports = &.{
            .{
                .name = "tracy-options",
                .module = options.createModule(),
            },
        },
    });

    tracy_module.addIncludePath(tracy_src.path("./public"));

    const tracy_client = if (shared) b.addSharedLibrary(.{
        .name = "tracy",
        .target = target,
        .optimize = optimize,
    }) else b.addStaticLibrary(.{
        .name = "tracy",
        .target = target,
        .optimize = optimize,
    });

    if (target.result.os.tag == .windows) {
        tracy_client.linkSystemLibrary("dbghelp");
        tracy_client.linkSystemLibrary("ws2_32");
    }
    tracy_client.linkLibCpp();
    tracy_client.addCSourceFile(.{
        .file = tracy_src.path("./public/TracyClient.cpp"),
        .flags = if (target.result.os.tag == .windows) &.{"-fms-extensions"} else &.{},
    });
    inline for (tracy_header_files) |header| {
        tracy_client.installHeader(
            tracy_src.path(header[0]),
            header[1],
        );
    }
    if (tracy_enable)
        tracy_client.defineCMacro("TRACY_ENABLE", null);
    if (tracy_on_demand)
        tracy_client.defineCMacro("TRACY_ON_DEMAND", null);
    if (tracy_callstack) |depth| {
        tracy_client.defineCMacro("TRACY_CALLSTACK", "\"" ++ digits2(depth) ++ "\"");
    }
    if (tracy_no_callstack)
        tracy_client.defineCMacro("TRACY_NO_CALLSTACK", null);
    if (tracy_no_callstack_inlines)
        tracy_client.defineCMacro("TRACY_NO_CALLSTACK_INLINES", null);
    if (tracy_only_localhost)
        tracy_client.defineCMacro("TRACY_ONLY_LOCALHOST", null);
    if (tracy_no_broadcast)
        tracy_client.defineCMacro("TRACY_NO_BROADCAST", null);
    if (tracy_only_ipv4)
        tracy_client.defineCMacro("TRACY_ONLY_IPV4", null);
    if (tracy_no_code_transfer)
        tracy_client.defineCMacro("TRACY_NO_CODE_TRANSFER", null);
    if (tracy_no_context_switch)
        tracy_client.defineCMacro("TRACY_NO_CONTEXT_SWITCH", null);
    if (tracy_no_exit)
        tracy_client.defineCMacro("TRACY_NO_EXIT", null);
    if (tracy_no_sampling)
        tracy_client.defineCMacro("TRACY_NO_SAMPLING", null);
    if (tracy_no_verify)
        tracy_client.defineCMacro("TRACY_NO_VERIFY", null);
    if (tracy_no_vsync_capture)
        tracy_client.defineCMacro("TRACY_NO_VSYNC_CAPTURE", null);
    if (tracy_no_frame_image)
        tracy_client.defineCMacro("TRACY_NO_FRAME_IMAGE", null);
    if (tracy_no_system_tracing)
        tracy_client.defineCMacro("TRACY_NO_SYSTEM_TRACING", null);
    if (tracy_delayed_init)
        tracy_client.defineCMacro("TRACY_DELAYED_INIT", null);
    if (tracy_manual_lifetime)
        tracy_client.defineCMacro("TRACY_MANUAL_LIFETIME", null);
    if (tracy_fibers)
        tracy_client.defineCMacro("TRACY_FIBERS", null);
    if (tracy_no_crash_handler)
        tracy_client.defineCMacro("TRACY_NO_CRASH_HANDLER", null);
    if (tracy_timer_fallback)
        tracy_client.defineCMacro("TRACY_TIMER_FALLBACK", null);
    if (shared and target.result.os.tag == .windows)
        tracy_client.defineCMacro("TRACY_EXPORTS", null);
    b.installArtifact(tracy_client);
}

fn digits2(value: usize) [2]u8 {
    return ("0001020304050607080910111213141516171819" ++
        "2021222324252627282930313233343536373839" ++
        "4041424344454647484950515253545556575859" ++
        "6061626364656667686970717273747576777879" ++
        "8081828384858687888990919293949596979899")[value * 2 ..][0..2].*;
}

const tracy_header_files = [_][2][]const u8{
    .{ "./public/tracy/TracyC.h", "tracy/TracyC.h" },
    .{ "./public/tracy/Tracy.hpp", "tracy/Tracy.hpp" },
    .{ "./public/tracy/TracyD3D11.hpp", "tracy/TracyD3D11.hpp" },
    .{ "./public/tracy/TracyD3D12.hpp", "tracy/TracyD3D12.hpp" },
    .{ "./public/tracy/TracyLua.hpp", "tracy/TracyLua.hpp" },
    .{ "./public/tracy/TracyOpenCL.hpp", "tracy/TracyOpenCL.hpp" },
    .{ "./public/tracy/TracyOpenGL.hpp", "tracy/TracyOpenGL.hpp" },
    .{ "./public/tracy/TracyVulkan.hpp", "tracy/TracyVulkan.hpp" },

    .{ "./public/client/tracy_concurrentqueue.h", "client/tracy_concurrentqueue.h" },
    .{ "./public/client/tracy_rpmalloc.hpp", "client/tracy_rpmalloc.hpp" },
    .{ "./public/client/tracy_SPSCQueue.h", "client/tracy_SPSCQueue.h" },
    .{ "./public/client/TracyArmCpuTable.hpp", "client/TracyArmCpuTable.hpp" },
    .{ "./public/client/TracyCallstack.h", "client/TracyCallstack.h" },
    .{ "./public/client/TracyCallstack.hpp", "client/TracyCallstack.hpp" },
    .{ "./public/client/TracyCpuid.hpp", "client/TracyCpuid.hpp" },
    .{ "./public/client/TracyDebug.hpp", "client/TracyDebug.hpp" },
    .{ "./public/client/TracyDxt1.hpp", "client/TracyDxt1.hpp" },
    .{ "./public/client/TracyFastVector.hpp", "client/TracyFastVector.hpp" },
    .{ "./public/client/TracyLock.hpp", "client/TracyLock.hpp" },
    .{ "./public/client/TracyProfiler.hpp", "client/TracyProfiler.hpp" },
    .{ "./public/client/TracyRingBuffer.hpp", "client/TracyRingBuffer.hpp" },
    .{ "./public/client/TracyScoped.hpp", "client/TracyScoped.hpp" },
    .{ "./public/client/TracyStringHelpers.hpp", "client/TracyStringHelpers.hpp" },
    .{ "./public/client/TracySysPower.hpp", "client/TracySysPower.hpp" },
    .{ "./public/client/TracySysTime.hpp", "client/TracySysTime.hpp" },
    .{ "./public/client/TracySysTrace.hpp", "client/TracySysTrace.hpp" },
    .{ "./public/client/TracyThread.hpp", "client/TracyThread.hpp" },

    .{ "./public/common/tracy_lz4.hpp", "common/tracy_lz4.hpp" },
    .{ "./public/common/tracy_lz4hc.hpp", "common/tracy_lz4hc.hpp" },
    .{ "./public/common/TracyAlign.hpp", "common/TracyAlign.hpp" },
    .{ "./public/common/TracyAlloc.hpp", "common/TracyAlloc.hpp" },
    .{ "./public/common/TracyApi.h", "common/TracyApi.h" },
    .{ "./public/common/TracyColor.hpp", "common/TracyColor.hpp" },
    .{ "./public/common/TracyForceInline.hpp", "common/TracyForceInline.hpp" },
    .{ "./public/common/TracyMutex.hpp", "common/TracyMutex.hpp" },
    .{ "./public/common/TracyProtocol.hpp", "common/TracyProtocol.hpp" },
    .{ "./public/common/TracyQueue.hpp", "common/TracyQueue.hpp" },
    .{ "./public/common/TracySocket.hpp", "common/TracySocket.hpp" },
    .{ "./public/common/TracyStackFrames.hpp", "common/TracyStackFrames.hpp" },
    .{ "./public/common/TracySystem.hpp", "common/TracySystem.hpp" },
    .{ "./public/common/TracyUwp.hpp", "common/TracyUwp.hpp" },
    .{ "./public/common/TracyYield.hpp", "common/TracyYield.hpp" },
};
