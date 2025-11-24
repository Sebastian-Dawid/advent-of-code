const std = @import("std");

const Shape = enum(i8) {
    rock = 1,
    paper = 2,
    scissors = 3,
};

fn scoreRound(shape1: Shape, shape2: Shape) u8 {
    const diff: i8 = @mod(@intFromEnum(shape1) - @intFromEnum(shape2), 3);
    const result: u8 = @intCast(@intFromEnum(shape2));
    switch (diff) {
        0 => return result + 3,
        1 => return result,
        2 => return result + 6,
        else => unreachable,
    }
}

fn part1(file: std.fs.File) !usize {
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);
    var result: usize = 0;
    while (reader.interface.takeDelimiter('\n')) |line| {
        if (line) |str| {
            const first: i8 = @intCast(str[0] - 'A' + 1);
            const second: i8 = @intCast(str[2] - 'X' + 1);
            result += scoreRound(@enumFromInt(first), @enumFromInt(second));
        } else break;
    } else |err| return err;
    return result;
}

const results = [_]i8{ 1, 0, 2 };
fn part2(file: std.fs.File) !usize {
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);
    var result: usize = 0;
    while (reader.interface.takeDelimiter('\n')) |line| {
        if (line) |str| {
            const first: i8 = @intCast(str[0] - 'A' + 1);
            var second: i8 = first - results[@intCast(str[2] - 'X')];
            if (second < 1) second += 3;
            result += scoreRound(@enumFromInt(first), @enumFromInt(second));
        } else break;
    } else |err| return err;
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

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Part 1: {}\n", .{ try part1(file) });
    try file.seekTo(0);
    try stdout.print("Part 2: {}\n", .{ try part2(file) });
    try stdout.flush();
}

test "Part 1" {
    const file = std.fs.cwd().openFile("../inputs/2022/day02-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    try std.testing.expectEqual(15, part1(file));
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2022/day02-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    try std.testing.expectEqual(12, part2(file));
}
