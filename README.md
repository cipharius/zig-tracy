# Zig tracy client
Easy to use bindings for the tracy client C API.

## Dependencies

* Zig 0.12.0-dev.3437+af0668d6c
* Tracy 0.10.0 (only for viewing the profiling session, this repository is only concerned with client matters)

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

See `./example` for how to set up `zig-tracy` with a Zig project.

In summary:
* Declare `zig-tracy` as a dependency in the `build.zig.zon`
* Configure `zig-tracy` dependency in `build.zig`
* Instrument the code using the provided Zig module
* Use Tracy UI/server to connect to the instrumented Zig application and explore the profiler data

## Building as a Shared Library

If your project needs to call tracy functions from multiple DLLs, then you need to build the tracy client as a shared library.

This is accomplished by passing the `shared` option, and (if you're using Windows) installing the resulting shared library next to your exe.

```zig
    const tracy = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
        .shared = true,
    });

    const install_dir = std.Build.Step.InstallArtifact.Options.Dir{ .override = .{ .bin = {} } };
    const install_tracy = b.addInstallArtifact(tracy.artifact("tracy"), .{
        .dest_dir = install_dir,
        .pdb_dir = install_dir,
    });
    b.getInstallStep().dependOn(&install_tracy.step);
```

For additional context, see section 2.1.5 of the Tracy manual, "Setup for multi-DLL projects".

## Todo / Ideas

* Figure out why system sampling is broken
* Tracy fibers support, would make sense paired with Zig async
* GPU zone markup support
* Test callstack support
