const std = @import("std");
const tracy = @import("tracy");

var finalise_threads: std.Thread.ResetEvent = .{};

export fn handleSigInt(_: c_int) void {
    finalise_threads.set();
}

pub fn main() !void {
    tracy.setThreadName("Main");
    defer tracy.message("Graceful main thread exit");

    std.posix.sigaction(std.posix.SIG.INT, &.{
        .handler = .{ .handler = handleSigInt },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    }, null);

    const other_thread = try std.Thread.spawn(.{}, otherThread, .{});
    defer other_thread.join();

    while (!finalise_threads.isSet()) {
        tracy.frameMark();

        const zone = tracy.initZone(@src(), .{ .name = "Important work" });
        defer zone.deinit();
        std.Thread.sleep(100);
    }
}

fn otherThread() void {
    tracy.setThreadName("Other");
    defer tracy.message("Graceful other thread exit");

    var os_allocator = tracy.TracingAllocator.init(std.heap.page_allocator);

    var arena = std.heap.ArenaAllocator.init(os_allocator.allocator());
    defer arena.deinit();

    var tracing_allocator = tracy.TracingAllocator.initNamed("arena", arena.allocator());
    const allocator = tracing_allocator.allocator();

    var stack = std.ArrayList(u8).empty;
    defer stack.deinit(allocator);

    const stdin = std.fs.File.stdin().deprecatedReader();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    while (!finalise_threads.isSet()) {
        const zone = tracy.initZone(@src(), .{ .name = "IO loop" });
        defer zone.deinit();

        stdout.print("Enter string: ", .{}) catch break;
        stdout.flush() catch break;

        const stream_zone = tracy.initZone(@src(), .{ .name = "Writer.streamUntilDelimiter" });
        stdin.streamUntilDelimiter(stack.writer(allocator), '\n', null) catch break;
        stream_zone.deinit();

        const toowned_zone = tracy.initZone(@src(), .{ .name = "ArrayList.toOwnedSlice" });
        const str = stack.toOwnedSlice(allocator) catch break;
        defer allocator.free(str);
        toowned_zone.deinit();

        const reverse_zone = tracy.initZone(@src(), .{ .name = "std.mem.reverse" });
        std.mem.reverse(u8, str);
        reverse_zone.deinit();

        stdout.print("Reversed: {s}\n", .{str}) catch break;
    }
}
