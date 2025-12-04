const std = @import("std");
const ResolvedTarget = std.Build.ResolvedTarget;
const OptimizeMode = std.builtin.OptimizeMode;

const asm_days = [_]usize{ 1, 2, 3, 4 };
const zig_days = [_]usize{ 1 };

const Options = struct {
    root_file: []const u8,
    target: ResolvedTarget,
    optimize: OptimizeMode,
    assembly: bool,
};

fn addDay(b: *std.Build, day: usize, options: Options) !void {
    const mod = b.createModule(.{
        .root_source_file = if (options.assembly) null else b.path(options.root_file),
        .target = options.target,
        .optimize = options.optimize,
    });

    if (options.assembly) {
        mod.addAssemblyFile(b.path(options.root_file));
        mod.addAssemblyFile(b.path("src/utils.s"));
    }

    var buf: [1024]u8 = undefined;
    const name = try std.fmt.bufPrint(&buf, "day{:02}-{s}", .{ day, if (options.assembly) "asm" else "zig" });

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = mod,
    });

    b.installArtifact(exe);

    if (!options.assembly) {
        const exe_tests = b.addTest(.{
            .root_module = mod,
        });
        const run_exe_test = b.addRunArtifact(exe_tests);
        const test_name = try std.fmt.bufPrint(&buf, "test-day{:02}", .{ day });
        const test_step = b.step(test_name, "Run unit tests for zig implementation");
        test_step.dependOn(&run_exe_test.step);
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var buf: [1024]u8 = undefined;
    for (asm_days) |i| {
        const filename = try std.fmt.bufPrint(&buf, "src/day{:02}.s", .{ i });
        try addDay(b, i, .{
            .root_file = filename,
            .target = target,
            .optimize = optimize,
            .assembly = true,
        });
    }

    for (zig_days) |i| {
        const filename = try std.fmt.bufPrint(&buf, "src/day{:02}.zig", .{ i });
        try addDay(b, i, .{
            .root_file = filename,
            .target = target,
            .optimize = optimize,
            .assembly = false,
        });
    }
}
