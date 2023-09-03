const std = @import("std");

const tracy_version = std.SemanticVersion{
    .major = 0,
    .minor = 9,
    .patch = 2,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tracy_enable = b.option(bool, "tracy-enable", "Enable profiling") orelse true;
    const tracy_on_demand = b.option(bool, "tracy-on-demand", "On-demand profiling") orelse false;
    const tracy_callstack = b.option(bool, "tracy-callstack", "Enfore callstack collection for tracy regions") orelse false;
    const tracy_no_callstack = b.option(bool, "tracy-no-callstack", "Disable all callstack related functionality") orelse false;
    const tracy_no_callstack_inlines = b.option(bool, "tracy-no-callstack-inlines", "Disables the inline functions in callstacks") orelse false;
    const tracy_only_localhost = b.option(bool, "tracy-only-localhost", "Only listen on the localhost interface") orelse false;
    const tracy_no_broadcast = b.option(bool, "tracy-no-broadcast", "Disable client discovery by broadcast to local network") orelse false;
    const tracy_only_ipv4 = b.option(bool, "tracy-only-ipv4", "Tracy will only accept connections on IPv4 addresses (disable IPv6)") orelse false;
    const tracy_no_code_transfer = b.option(bool, "tracy-no-code-transfer", "Disable collection of source code") orelse false;
    const tracy_no_context_switch = b.option(bool, "tracy-no-context-switch", "Disable capture of context switches") orelse false;
    const tracy_no_exit = b.option(bool, "tracy-no-exit", "Client executable does not exit until all profile data is sent to server") orelse false;
    const tracy_no_sampling = b.option(bool, "tracy-no-sampling", "Disable call stack sampling") orelse false;
    const tracy_no_verify = b.option(bool, "tracy-no-verify", "Disable zone validation for C API") orelse false;
    const tracy_no_vsync_capture = b.option(bool, "tracy-no-vsync-capture", "Disable capture of hardware Vsync events") orelse false;
    const tracy_no_frame_image = b.option(bool, "tracy-no-frame-image", "Disable the frame image support and its thread") orelse false;
    const tracy_no_system_tracing = b.option(bool, "tracy-no-system-tracing", "Disable systrace sampling") orelse false;
    const tracy_delayed_init = b.option(bool, "tracy-delayed-init", "Enable delayed initialization of the library (init on first call)") orelse false;
    const tracy_manual_lifetime = b.option(bool, "tracy-manual-lifetime", "Enable the manual lifetime management of the profile") orelse false;
    const tracy_fibers = b.option(bool, "tracy-fibers", "Enable fibers support") orelse false;
    const tracy_no_crash_handler = b.option(bool, "tracy-no-crash-handler", "Disable crash handling") orelse false;
    const tracy_timer_fallback = b.option(bool, "tracy-timer-fallback", "Use lower resolution timers") orelse false;

    const tracy_module = b.addModule("tracy", .{
        .source_file = .{ .path = "./src/tracy.zig" },
    });

    const tracy_client = b.addStaticLibrary(.{
        .name = "tracy",
        .target = target,
        .optimize = optimize,
    });
    tracy_client.addModule("tracy", tracy_module);
    tracy_client.linkLibCpp();
    tracy_client.addCSourceFile(.{
        .file = .{ .path = "./tracy/public/TracyClient.cpp" },
        .flags = &.{},
    });
    inline for (tracy_header_files) |header| {
        tracy_client.installHeader(header[0], header[1]);
    }
    if (tracy_enable)
        tracy_client.defineCMacro("TRACY_ENABLE", null);
    if (tracy_on_demand)
        tracy_client.defineCMacro("TRACY_ON_DEMAND", null);
    if (tracy_callstack)
        tracy_client.defineCMacro("TRACY_CALLSTACK", null);
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
    b.installArtifact(tracy_client);
}

const tracy_header_files = [_][2][]const u8{
    .{ "./tracy/public/tracy/TracyC.h", "tracy/TracyC.h" },
    .{ "./tracy/public/tracy/Tracy.hpp", "tracy/Tracy.hpp" },
    .{ "./tracy/public/tracy/TracyD3D11.hpp", "tracy/TracyD3D11.hpp" },
    .{ "./tracy/public/tracy/TracyD3D12.hpp", "tracy/TracyD3D12.hpp" },
    .{ "./tracy/public/tracy/TracyLua.hpp", "tracy/TracyLua.hpp" },
    .{ "./tracy/public/tracy/TracyOpenCL.hpp", "tracy/TracyOpenCL.hpp" },
    .{ "./tracy/public/tracy/TracyOpenGL.hpp", "tracy/TracyOpenGL.hpp" },
    .{ "./tracy/public/tracy/TracyVulkan.hpp", "tracy/TracyVulkan.hpp" },

    .{ "./tracy/public/client/tracy_concurrentqueue.h", "client/tracy_concurrentqueue.h" },
    .{ "./tracy/public/client/tracy_rpmalloc.hpp", "client/tracy_rpmalloc.hpp" },
    .{ "./tracy/public/client/tracy_SPSCQueue.h", "client/tracy_SPSCQueue.h" },
    .{ "./tracy/public/client/TracyArmCpuTable.hpp", "client/TracyArmCpuTable.hpp" },
    .{ "./tracy/public/client/TracyCallstack.h", "client/TracyCallstack.h" },
    .{ "./tracy/public/client/TracyCallstack.hpp", "client/TracyCallstack.hpp" },
    .{ "./tracy/public/client/TracyCpuid.hpp", "client/TracyCpuid.hpp" },
    .{ "./tracy/public/client/TracyDebug.hpp", "client/TracyDebug.hpp" },
    .{ "./tracy/public/client/TracyDxt1.hpp", "client/TracyDxt1.hpp" },
    .{ "./tracy/public/client/TracyFastVector.hpp", "client/TracyFastVector.hpp" },
    .{ "./tracy/public/client/TracyLock.hpp", "client/TracyLock.hpp" },
    .{ "./tracy/public/client/TracyProfiler.hpp", "client/TracyProfiler.hpp" },
    .{ "./tracy/public/client/TracyRingBuffer.hpp", "client/TracyRingBuffer.hpp" },
    .{ "./tracy/public/client/TracyScoped.hpp", "client/TracyScoped.hpp" },
    .{ "./tracy/public/client/TracyStringHelpers.hpp", "client/TracyStringHelpers.hpp" },
    .{ "./tracy/public/client/TracySysPower.hpp", "client/TracySysPower.hpp" },
    .{ "./tracy/public/client/TracySysTime.hpp", "client/TracySysTime.hpp" },
    .{ "./tracy/public/client/TracySysTrace.hpp", "client/TracySysTrace.hpp" },
    .{ "./tracy/public/client/TracyThread.hpp", "client/TracyThread.hpp" },

    .{ "./tracy/public/common/tracy_lz4.hpp", "common/tracy_lz4.hpp" },
    .{ "./tracy/public/common/tracy_lz4hc.hpp", "common/tracy_lz4hc.hpp" },
    .{ "./tracy/public/common/TracyAlign.hpp", "common/TracyAlign.hpp" },
    .{ "./tracy/public/common/TracyAlloc.hpp", "common/TracyAlloc.hpp" },
    .{ "./tracy/public/common/TracyApi.h", "common/TracyApi.h" },
    .{ "./tracy/public/common/TracyColor.hpp", "common/TracyColor.hpp" },
    .{ "./tracy/public/common/TracyForceInline.hpp", "common/TracyForceInline.hpp" },
    .{ "./tracy/public/common/TracyMutex.hpp", "common/TracyMutex.hpp" },
    .{ "./tracy/public/common/TracyProtocol.hpp", "common/TracyProtocol.hpp" },
    .{ "./tracy/public/common/TracyQueue.hpp", "common/TracyQueue.hpp" },
    .{ "./tracy/public/common/TracySocket.hpp", "common/TracySocket.hpp" },
    .{ "./tracy/public/common/TracyStackFrames.hpp", "common/TracyStackFrames.hpp" },
    .{ "./tracy/public/common/TracySystem.hpp", "common/TracySystem.hpp" },
    .{ "./tracy/public/common/TracyUwp.hpp", "common/TracyUwp.hpp" },
    .{ "./tracy/public/common/TracyYield.hpp", "common/TracyYield.hpp" },
};
