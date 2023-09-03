const std = @import("std");
const c = @cImport({
    @cInclude("tracy/TracyC.h");
});

pub fn setThreadName(name: [:0]const u8) void {
    c.___tracy_set_thread_name(name);
}
