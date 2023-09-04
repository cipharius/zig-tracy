const std = @import("std");
const options = @import("tracy-options");
const c = @cImport({
    if (options.tracy_enable) @cDefine("TRACY_ENABLE", {});
    if (options.tracy_on_demand) @cDefine("TRACY_ON_DEMAND", {});
    if (options.tracy_callstack) |depth| @cDefine("TRACY_CALLSTACK", "\"" ++ digits2(depth) ++ "\"");
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

pub inline fn setThreadName(comptime name: [:0]const u8) void {
    if (!options.tracy_enable) return;
    c.___tracy_set_thread_name(name);
}

pub inline fn startupProfiler() void {
    if (!options.tracy_enable) return;
    if (!options.tracy_manual_lifetime) return;
    c.___tracy_startup_profiler();
}

pub inline fn shutdownProfiler() void {
    if (!options.tracy_enable) return;
    if (!options.tracy_manual_lifetime) return;
    c.___tracy_shutdown_profiler();
}

pub inline fn isConnected() bool {
    if (!options.tracy_enable) return false;
    return c.___tracy_connected() > 0;
}

pub inline fn frameMark() void {
    if (!options.tracy_enable) return;
    c.___tracy_emit_frame_mark(null);
}

pub inline fn frameMarkNamed(comptime name: [:0]const u8) void {
    if (!options.tracy_enable) return;
    c.___tracy_emit_frame_mark(name);
}

const DiscontinuousFrame = struct{
    name: [:0]const u8,

    pub inline fn deinit(frame: *const DiscontinuousFrame) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_frame_mark_end(frame.name);
    }
};

pub inline fn initDiscontinuousFrame(comptime name: [:0]const u8) DiscontinuousFrame {
    if (!options.tracy_enable) return .{ .name = name };
    c.___tracy_emit_frame_mark_start(name);
    return .{ .name = name };
}

pub inline fn frameImage(image: *anyopaque, width: u16, height: u16, offset: u8, flip: bool) void {
    if (!options.tracy_enable) return;
    c.___tracy_emit_frame_mark_image(image, width, height, offset, @as(c_int, @intFromBool(flip)));
}

pub const ZoneOptions = struct{
    active: bool = true,
    name: ?[]const u8 = null,
    color: ?u32 = null,
};

const ZoneContext = extern struct{
    ctx: c.___tracy_c_zone_context,

    pub inline fn deinit(zone: *const ZoneContext) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_end(zone.ctx);
    }

    pub inline fn name(zone: *const ZoneContext, zone_name: []const u8) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_name(zone.ctx, zone_name.ptr, zone_name.len);
    }

    pub inline fn text(zone: *const ZoneContext, zone_text: []const u8) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_text(zone.ctx, zone_text.ptr, zone_text.len);
    }

    pub inline fn color(zone: *const ZoneContext, zone_color: u32) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_color(zone.ctx, zone_color);
    }

    pub inline fn value(zone: *const ZoneContext, zone_value: u64) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_value(zone.ctx, zone_value);
    }
};

pub inline fn initZone(comptime src: std.builtin.SourceLocation, comptime opts: ZoneOptions) ZoneContext {
    if (!options.tracy_enable) return .{ .ctx = 0 };
    const active: c_int = @intFromBool(opts.active);

    const static = struct{
        var src_loc = c.___tracy_source_location_data{
            .name = if (opts.name) |name| name.ptr else null,
            .function = src.fn_name.ptr,
            .file = src.file,
            .line = 0,
            .color = opts.color orelse 0,
        };
    };

    // src.line magically is not comptime https://github.com/ziglang/zig/pull/12016#issuecomment-1178092847
    static.src_loc.line = src.line;

    if (!options.tracy_no_callstack) {
        if (options.tracy_callstack) |depth| {
            return .{
                .ctx = c.___tracy_emit_zone_begin_callstack(&static.src_loc, depth, active),
            };
        }
    }

    return .{
        .ctx = c.___tracy_emit_zone_begin(&static.src_loc, active),
    };
}

pub inline fn plot(comptime T: type, comptime name: [:0]const u8, value: T) void {
    if (!options.tracy_enable) return;

    const type_info = @typeInfo(T);
    switch (type_info) {
        .Int => |int_type| {
            if (int_type.bits > 64) @panic("Too large int to plot");
            if (int_type.signedness == .unsigned and int_type.bits > 63) @panic("Too large unsigned int to plot");
            c.___tracy_emit_plot_int(name, value);
        },
        .Float => |float_type| {
            if (float_type.bits <= 32) {
                c.___tracy_emit_plot_float(name, value);
            } else if (float_type.bits <= 64) {
                c.___tracy_emit_plot(name, value);
            } else {
                @panic("Too large float to plot");
            }
        },
        else => @panic("Unsupported plot value type"),
    }
}

pub const PlotType = enum(c_int){
    Number,
    Memory,
    Percentage,
    Watt,
};

pub const PlotConfig = struct{
    plot_type: PlotType,
    step: c_int,
    fill: c_int,
    color: u32,
};

pub inline fn plotConfig(comptime name: [:0]const u8, comptime config: PlotConfig) void {
    if (!options.tracy_enable) return;
    c.___tracy_emit_plot_config(
        name,
        @intFromEnum(config.plot_type),
        config.step,
        config.fill,
        config.color,
    );
}

pub inline fn message(comptime msg: [:0]const u8) void {
    if (!options.tracy_enable) return;
    const depth = options.tracy_callstack orelse 0;
    c.___tracy_emit_messageL(msg, depth);
}

pub inline fn messageColor(comptime msg: [:0]const u8, color: u32) void {
    if (!options.tracy_enable) return;
    const depth = options.tracy_callstack orelse 0;
    c.___tracy_emit_messageLC(msg, color, depth);
}

const tracy_message_buffer_size = if (options.tracy_enable) 4096 else 0;
threadlocal var tracy_message_buffer: [tracy_message_buffer_size]u8 = undefined;
threadlocal var tracy_message_stream = std.io.fixedBufferStream(&tracy_message_buffer);

pub inline fn print(comptime fmt: []const u8, args: anytype) void {
    if (!options.tracy_enable) return;
    const depth = options.tracy_callstack orelse 0;

    tracy_message_stream.reset();
    tracy_message_stream.writer().print(fmt, args) catch {};

    const written = tracy_message_stream.getWritten();
    c.___tracy_emit_message(written.ptr, written.len, depth);
}

pub inline fn printColor(comptime fmt: []const u8, args: anytype, color: u32) void {
    if (!options.tracy_enable) return;
    const depth = options.tracy_callstack orelse 0;

    tracy_message_stream.reset();
    tracy_message_stream.writer().print(fmt, args) catch {};

    const written = tracy_message_stream.getWritten();
    c.___tracy_emit_messageC(written.ptr, written.len, color, depth);
}

pub inline fn printAppInfo(comptime fmt: []const u8, args: anytype) void {
    if (!options.tracy_enable) return;

    tracy_message_stream.reset();
    tracy_message_stream.writer().print(fmt, args) catch {};

    const written = tracy_message_stream.getWritten();
    c.___tracy_emit_message_appinfo(written.ptr, written.len);
}

fn digits2(value: usize) [2]u8 {
    return ("0001020304050607080910111213141516171819" ++
        "2021222324252627282930313233343536373839" ++
        "4041424344454647484950515253545556575859" ++
        "6061626364656667686970717273747576777879" ++
        "8081828384858687888990919293949596979899")[value * 2 ..][0..2].*;
}

