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

## Todo / Ideas

* Tracy fibers support, would make sense paired with Zig async
* Memory profiling support by creating custom allocator that instruments and acts as proxy
* GPU zone markup support
* Make it possible to fetch this module via zig package manager
* Test callstack support
