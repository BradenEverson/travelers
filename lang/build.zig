// build.zig
const std = @import("std");

const number_of_pages = 2;

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "traveler",
        .root_source_file = b.path("src/main.zig"),
        .target = b.graph.host,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the interpreter");

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    run_step.dependOn(&run_cmd.step);

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    var wasm_exe = b.addExecutable(.{
        .name = "traveler_wasm",
        .root_source_file = b.path("src/wasm.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
    });

    wasm_exe.global_base = 6560;
    wasm_exe.entry = .disabled;
    wasm_exe.rdynamic = true;
    wasm_exe.import_memory = true;
    wasm_exe.stack_size = std.wasm.page_size;

    wasm_exe.initial_memory = std.wasm.page_size * number_of_pages;
    wasm_exe.max_memory = std.wasm.page_size * number_of_pages;

    b.installArtifact(wasm_exe);

    const wasm_cmd = b.addInstallArtifact(wasm_exe, .{ .dest_dir = .{ .override = .{ .custom = "../../game/wasm/" } } });
    wasm_cmd.step.dependOn(b.getInstallStep());

    const wasm_step = b.step("wasm", "Build for wasm");
    wasm_step.dependOn(&wasm_cmd.step);
}
