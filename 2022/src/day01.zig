const std = @import("std");
const Allocator = std.mem.Allocator;

fn parse(file: std.fs.File, allocator: Allocator) ![]usize {
    var values: std.ArrayList(usize) = .empty;
    defer values.deinit(allocator);

    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);

    var value: usize = 0;
    while (reader.interface.takeDelimiter('\n')) |line| {
        if (line) |str| {
            if (str.len == 0) {
                for (values.items, 0..) |v, i| {
                    if (value > v) {
                        try values.insert(allocator, i, value);
                        break;
                    }
                } else try values.append(allocator, value);
                value = 0;
                continue;
            }
            value += try std.fmt.parseUnsigned(usize, str, 0);
        } else break;
    } else |err| return err;

    return try values.toOwnedSlice(allocator);
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
    const values = try parse(file, allocator);
    defer allocator.free(values);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Part 1: {}\n", .{ values[0] });
    try stdout.print("Part 2: {}\n", .{ values[0] + values[1] + values[2] });
    try stdout.flush();
}

test "Part 1" {
    const file = std.fs.cwd().openFile("../inputs/2022/day01-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const values = try parse(file, allocator);
    defer allocator.free(values);
    try std.testing.expectEqual(24000, values[0]);
}

test "Part 2" {
    const file = std.fs.cwd().openFile("../inputs/2022/day01-test", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const values = try parse(file, allocator);
    defer allocator.free(values);
    try std.testing.expectEqual(45000, values[0] + values[1] + values[2]);
}
