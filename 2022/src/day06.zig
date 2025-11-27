const std = @import("std");

fn findMarker(buffer: []u8, marker: usize) usize {
    var lut = [_]u8{0} ** 26;

    var i: usize = 0;
    while (i < marker) : (i += 1) {
        lut[buffer[i] - 'a'] += 1;
    }
    outer: while (i < buffer.len) : (i += 1) {
        lut[buffer[i] - 'a'] += 1;
        lut[buffer[i - marker] - 'a'] -= 1;

        for (lut) |c| {
            if (c > 1) continue :outer;
        } else return i + 1;
    }

    return 0;
}

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

    var buffer: [8192]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;
    const message = try reader.takeDelimiterExclusive('\n');

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Part 1: {}\n", .{ findMarker(message, 4) });
    try stdout.print("Part 2: {}\n", .{ findMarker(message, 14) });
    try stdout.flush();
}

test "Part 1" {
    const file = std.fs.cwd().openFile("../inputs/2022/day06-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    var buffer: [8192]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;
    const message = try reader.takeDelimiterExclusive('\n');
    try std.testing.expectEqual(7, findMarker(message, 4));
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2022/day06-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    var buffer: [8192]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;
    const message = try reader.takeDelimiterExclusive('\n');
    try std.testing.expectEqual(19, findMarker(message, 14));
}
