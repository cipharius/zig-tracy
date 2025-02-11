const std = @import("std");
const tracy = @import("tracy");

var finalise_threads = std.atomic.Value(bool).init(false);

fn handleSigInt(_: c_int) callconv(.C) void {
    finalise_threads.store(true, .release);
}

pub fn main() !void {
    tracy.setThreadName("Main");
    defer tracy.message("Graceful main thread exit");

    std.posix.sigaction(std.posix.SIG.INT, &.{
        .handler = .{ .handler = handleSigInt },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    }, null);

    const other_thread = try std.Thread.spawn(.{}, otherThread, .{});
    defer other_thread.join();

    while (!finalise_threads.load(.acquire)) {
        tracy.frameMark();

        const zone = tracy.initZone(@src(), .{ .name = "Important work" });
        defer zone.deinit();
        std.time.sleep(100);
    }
}

fn otherThread() void {
    tracy.setThreadName("Other");
    defer tracy.message("Graceful other thread exit");

    var os_allocator = tracy.TracingAllocator.init(std.heap.page_allocator);

    var arena = std.heap.ArenaAllocator.init(os_allocator.allocator());
    defer arena.deinit();

    var tracing_allocator = tracy.TracingAllocator.initNamed("arena", arena.allocator());

    var stack = std.ArrayList(u8).init(tracing_allocator.allocator());
    defer stack.deinit();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    while (!finalise_threads.load(.acquire)) {
        const zone = tracy.initZone(@src(), .{ .name = "IO loop" });
        defer zone.deinit();

        stdout.print("Enter string: ", .{}) catch break;

        const stream_zone = tracy.initZone(@src(), .{ .name = "Writer.streamUntilDelimiter" });
        stdin.streamUntilDelimiter(stack.writer(), '\n', null) catch break;
        stream_zone.deinit();

        const toowned_zone = tracy.initZone(@src(), .{ .name = "ArrayList.toOwnedSlice" });
        const str = stack.toOwnedSlice() catch break;
        defer tracing_allocator.allocator().free(str);
        toowned_zone.deinit();

        const reverse_zone = tracy.initZone(@src(), .{ .name = "std.mem.reverse" });
        std.mem.reverse(u8, str);
        reverse_zone.deinit();

        stdout.print("Reversed: {s}\n", .{str}) catch break;
    }
}
