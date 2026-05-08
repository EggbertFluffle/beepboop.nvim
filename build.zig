const std = @import("std");

const cross_compile_targets = [_]std.Target.Query {
    // .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    // .{ .cpu_arch = .aarch64, .os_tag = .macos, .abi = .gnu },
    // .{ .cpu_arch = .x86_64, .os_tag = .macos, .abi = .gnu },
    // .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu }
};

pub fn build_for_target(b: *std.Build, target: std.Build.ResolvedTarget) void {
    const arch = target.query.cpu_arch;
    const os = target.query.os_tag;

    const target_name = std.fmt.allocPrint(std.heap.page_allocator, "boopbeep-{s}-{s}", .{
        switch (arch.?) {
            .aarch64 => "aarch64",
            .x86_64 => "x86",
            .arm => "arm",
            else => "arch"
        },
        switch (os.?) {
            .windows => "windows",
            .linux => "linux",
            .macos => "macos",
            else => "os"
        }
    }) catch "boopbeep";

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
        .link_libc = true
    });

    root_mod.addCSourceFile(.{
        .file = b.path("src/miniaudio.c"),
        .flags = &.{
            // "-DMA_IMPLEMENTATION",
            // "-march=native",     // OR use this to auto-detect your CPU features
            "-fno-sanitize=undefined",  // Clang 21 inserts UD2 traps; disable them
        }
    });
    root_mod.addIncludePath(b.path("lib/"));
    
    const exe = b.addExecutable(.{
        .name = target_name,
        .root_module = root_mod
    });

    b.installArtifact(exe);
}

pub fn build(b: *std.Build) void {
    for(cross_compile_targets) |target| {
        build_for_target(b, b.resolveTargetQuery(target));
    }
}
