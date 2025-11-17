const std = @import("std");
const ResolvedTarget = std.Build.ResolvedTarget;
const OptimizeMode = std.builtin.OptimizeMode;

const Options = struct {
    root_file: []const u8,
    target: ResolvedTarget,
    optimize: OptimizeMode,
    assembly: bool,
};

fn addDay(b: *std.Build, name: []const u8, options: Options) void {
    const mod = b.createModule(.{
        .root_source_file = if (options.assembly) null else b.path(options.root_file),
        .target = options.target,
        .optimize = options.optimize,
    });
    if (options.assembly) {
        mod.addAssemblyFile(b.path(options.root_file));
    }

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = mod,
    });

    b.installArtifact(exe);

    // const step = b.step(name, "Run Day");
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    addDay(b, "template-zig", .{
        .root_file = "src/template.zig",
        .target = target,
        .optimize = optimize,
        .assembly = false,
    });
    addDay(b, "template-asm", .{
        .root_file = "src/template.s",
        .target = target,
        .optimize = optimize,
        .assembly = true,
    });
}
