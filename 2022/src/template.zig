const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    const filename = args.next() orelse return error.NoInputFile;

    const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Part 1: {}\n", .{ 0 });
    try stdout.print("Part 2: {}\n", .{ 0 });
    try stdout.flush();
}

test "Part 1" {
    const file = std.fs.cwd().openFile("../inputs/2022/day<n>-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    _ = allocator;
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2022/day<n>-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    _ = allocator;
}
