const std = @import("std");
const options = @import("tracy-options");
const c = @cImport({
    if (options.tracy_enable) @cDefine("TRACY_ENABLE", {});
    if (options.tracy_on_demand) @cDefine("TRACY_ON_DEMAND", {});
    if (options.tracy_callstack) @cDefine("TRACY_CALLSTACK", {});
    if (options.tracy_no_callstack) @cDefine("TRACY_NO_CALLSTACK", {});
    if (options.tracy_no_callstack_inlines) @cDefine("TRACY_NO_CALLSTACK_INLINES", {});
    if (options.tracy_only_localhost) @cDefine("TRACY_ONLY_LOCALHOST", {});
    if (options.tracy_no_broadcast) @cDefine("TRACY_NO_BROADCAST", {});
    if (options.tracy_only_ipv4) @cDefine("TRACY_ONLY_IPV4", {});
    if (options.tracy_no_code_transfer) @cDefine("TRACY_NO_CODE_TRANSFER", {});
    if (options.tracy_no_context_switch) @cDefine("TRACY_NO_CONTEXT_SWITCH", {});
    if (options.tracy_no_exit) @cDefine("TRACY_NO_EXIT", {});
    if (options.tracy_no_sampling) @cDefine("TRACY_NO_SAMPLING", {});
    if (options.tracy_no_verify) @cDefine("TRACY_NO_VERIFY", {});
    if (options.tracy_no_vsync_capture) @cDefine("TRACY_NO_VSYNC_CAPTURE", {});
    if (options.tracy_no_frame_image) @cDefine("TRACY_NO_FRAME_IMAGE", {});
    if (options.tracy_no_system_tracing) @cDefine("TRACY_NO_SYSTEM_TRACING", {});
    if (options.tracy_delayed_init) @cDefine("TRACY_DELAYED_INIT", {});
    if (options.tracy_manual_lifetime) @cDefine("TRACY_MANUAL_LIFETIME", {});
    if (options.tracy_fibers) @cDefine("TRACY_FIBERS", {});
    if (options.tracy_no_crash_handler) @cDefine("TRACY_NO_CRASH_HANDLER", {});
    if (options.tracy_timer_fallback) @cDefine("TRACY_TIMER_FALLBACK", {});

    @cInclude("tracy/TracyC.h");
});

pub fn setThreadName(name: [:0]const u8) void {
    c.___tracy_set_thread_name(name);
}
