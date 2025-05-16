const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "boopbeep",
        .root_source_file = b.path("src/boopbeep.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    exe.addCSourceFile(.{
        .file = b.path("src/lib/miniaudio/miniaudio.c"),
    });
    exe.addIncludePath(b.path("src/lib/miniaudio/"));

    // Different libs for different os
    // if (target.isWindows()) {
    //     exe.linkSystemLibrary("ole32");
    //     exe.linkSystemLibrary("user32");
    // } else if (target.isDarwin()) {
    //     exe.linkFramework("CoreAudio");
    //     exe.linkFramework("AudioToolbox");
    // } else if (target.isLinux()) {
    //     exe.linkSystemLibrary("m");
    //     exe.linkSystemLibrary("pthread");
    //     exe.linkSystemLibrary("dl");
    // }

    exe.linkLibC();

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run boopbeep");
    run_step.dependOn(&run_exe.step);
}
