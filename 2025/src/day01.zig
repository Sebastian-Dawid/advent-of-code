const std = @import("std");

fn part1(reader: *std.Io.Reader) usize {
    var dial: isize = 50;
    var result: usize = 0;
    while (reader.takeDelimiter('\n')) |line| {
        if (line) |str| {
            const dir: isize = if (str[0] == 'L') -1 else 1;
            const step = std.fmt.parseInt(isize, str[1..], 10) catch unreachable;
            dial = @mod(dial + dir*step, 100);
            if (dial == 0) result += 1;
        } else break;
    } else |_| unreachable;
    return result;
}

fn part2(reader: *std.Io.Reader) usize {
    var dial: isize = 50;
    var result: usize = 0;
    while (reader.takeDelimiter('\n')) |line| {
        if (line) |str| {
            const dir: isize = if (str[0] == 'L') -1 else 1;
            var step = std.fmt.parseInt(isize, str[1..], 10) catch unreachable;
            result += @intCast(@divTrunc(step, 100));
            step = @rem(step, 100);
            if (dial == 0 and (step == 0 or dir == -1)) result -= 1;
            dial = dial + dir*step;
            result += if (dial <= 0 or 100 <= dial) 1 else 0;
            dial = @mod(dial, 100);
        } else break;
    } else |_| unreachable;
    return result;
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

    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Part 1: {}\n", .{ part1(reader) });
    try file_reader.seekTo(0);
    try stdout.print("Part 2: {}\n", .{ part2(reader) });
    try stdout.flush();
}

test "Part 1" {
    const file = std.fs.cwd().openFile("../inputs/2025/day01-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;
    try std.testing.expectEqual(3, part1(reader));
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2025/day01-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&buffer);
    const reader = &file_reader.interface;
    try std.testing.expectEqual(6, part2(reader));
}
