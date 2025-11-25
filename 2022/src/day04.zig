const std = @import("std");

fn part1(file: std.fs.File) !usize {
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);
    var result: usize = 0;
    while (reader.interface.takeDelimiter('\n')) |line| {
        if (line) |str| {
            var it = std.mem.splitAny(u8, str, "-,");
            const a1 = if (it.next()) |v| try std.fmt.parseInt(usize, v, 10) else return error.InvalidFileContents;
            const a2 = if (it.next()) |v| try std.fmt.parseInt(usize, v, 10) else return error.InvalidFileContents;
            const b1 = if (it.next()) |v| try std.fmt.parseInt(usize, v, 10) else return error.InvalidFileContents;
            const b2 = if (it.next()) |v| try std.fmt.parseInt(usize, v, 10) else return error.InvalidFileContents;

            if (a1 == b1 or (b1 < a1 and a1 <= b2 and a2 <= b2) or (a1 < b1 and b1 <= a2 and b2 <= a2)) {
                result += 1;
            }
        } else break;
    } else |err| return err;
    return result;
}

fn part2(file: std.fs.File) !usize {
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);
    var result: usize = 0;
    while (reader.interface.takeDelimiter('\n')) |line| {
        if (line) |str| {
            var it = std.mem.splitAny(u8, str, "-,");
            const a1 = if (it.next()) |v| try std.fmt.parseInt(usize, v, 10) else return error.InvalidFileContents;
            const a2 = if (it.next()) |v| try std.fmt.parseInt(usize, v, 10) else return error.InvalidFileContents;
            const b1 = if (it.next()) |v| try std.fmt.parseInt(usize, v, 10) else return error.InvalidFileContents;
            const b2 = if (it.next()) |v| try std.fmt.parseInt(usize, v, 10) else return error.InvalidFileContents;

            if (a1 == b1 or (b1 < a1 and a1 <= b2) or (a1 < b1 and b1 <= a2)) {
                result += 1;
            }
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
    const file = std.fs.cwd().openFile("../inputs/2022/day04-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    try std.testing.expectEqual(2, part1(file));
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2022/day04-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    try std.testing.expectEqual(4, part2(file));
}
