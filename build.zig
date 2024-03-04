const std = @import("std");

const completed = 1;

pub fn concat(allocator: std.mem.Allocator, str1: []const u8, str2: []const u8) []const u8 {
    var result = allocator.alloc(u8, str1.len + str2.len) catch @panic("out of memory");
    std.mem.copy(u8, result[0..], str1);
    std.mem.copy(u8, result[str1.len..], str2);
    return result;
}

pub fn buildLab(allocator: std.mem.Allocator, b: *std.Build, lab: u4, runable: bool) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = std.builtin.Mode.ReleaseFast });
    const n = std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{lab}) catch @panic("out of memory");
    defer allocator.free(n);

    const lab_path = concat(allocator, n, "/main.zig");
    defer allocator.free(lab_path);

    const exe = b.addExecutable(.{
        .name = n,
        .root_source_file = .{ .path = lab_path },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    if (runable) {
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args|
            run_cmd.addArgs(args);
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = lab_path },
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

pub fn build(b: *std.Build) void {
    const allocator = std.heap.page_allocator;
    const lab = b.option(u4, "lab", "Lab to build (0: all without \"run\" target") orelse 0;

    if (lab == 0) {
        var i: u4 = 1;
        while (i <= completed) : (i += 1)
            buildLab(allocator, b, i, false);
    } else {
        buildLab(allocator, b, lab, true);
    }
}
