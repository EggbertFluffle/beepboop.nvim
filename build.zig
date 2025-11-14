const std = @import("std");

const cross_compile_targets = [_]std.Target.Query {
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    // .{ .cpu_arch = .aarch64, .os_tag = .macos, .abi = .gnu },
    // .{ .cpu_arch = .x86_64, .os_tag = .macos, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu }
};

pub fn build_for_target(b: *std.Build, target: std.Build.ResolvedTarget, strip: bool) void {
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
        .root_source_file = b.path("src/boopbeep.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
        .strip = strip,
        .link_libc = true,
    });

    root_mod.addCSourceFile(.{
        .file = b.path("src/lib/miniaudio/miniaudio.c"),
    });
    root_mod.addIncludePath(b.path("src/lib/miniaudio/"));
    
    const exe = b.addExecutable(.{
        .name = target_name,
        .root_module = root_mod
    });

    b.installArtifact(exe);
}

pub fn build(b: *std.Build) void {
    const strip = b.option(bool, "strip", "Strip debug information from compiled binaries") orelse false;

    std.debug.print("Cross compiling with strip={s}\n", .{if (strip) "true" else "false"});
    for(cross_compile_targets) |target| {
        build_for_target(b, b.resolveTargetQuery(target), strip);
    }
}
