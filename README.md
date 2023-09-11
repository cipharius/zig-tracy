# Zig tracy client
Easy to use bindings for the tracy client C API.

## Dependencies

* Zig 0.11.0
* Tracy 0.9.2 (only for viewing the profiling session, this repository is only concerned with client matters)

## Features

* Designed to integrate well with build.zig
* Builds and statically links the tracy client - perfect for cross-compilation
* Uses Zig comptime to nullify the tracy markup when building with tracy disabled
* Provides Zig friendly bindings for:
    * Zone markup
    * Frame markup
    * Plotting
    * Message printing
    * Memory tracing via custom allocator

## Usage

* Get a local checkout of this repository (no zig package manager support just yet)
* Register this package as anonymous dependency and install it in your compile step. Example:

```zig
const zig_tracy = b.anonymousDependency(
    "./libs/zig-tracy",
    @import("libs/zig-tracy/build.zig"),
    .{
        .target = target,
        .optimize = optimize,
    }
);

// ...

exe.addModule("tracy", zig_tracy.module("tracy"));
exe.linkLibrary(zig_tracy.artifact("tracy"));
```

* Import the tracy module and add markup to your zig code. Example:

```zig
const std = @import("std");
const tracy = @import("tracy");

fn hello() void {
    const zone = tracy.initZone(@src(), .{ .name = "hello" });
    defer zone.deinit();

    tracy.message("Hello world!");
}

pub fn main() void {
    tracy.setThreadName("Main");
    while (true) {
        tracy.frameMark();
        hello();
        std.time.sleep(100);
    }
}
```

* Use tracy UI/server to connect to the machine and explore the profiler data

## Todo / Ideas

* Figure out why system sampling is broken
* Tracy fibers support, would make sense paired with Zig async
* GPU zone markup support
* Make it possible to fetch this module via zig package manager
* Test callstack support
