const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

fn findSecretNumber(secret: usize) usize {
    var result = ((secret << 6) ^ secret) % 16_777_216;
    result = ((result >> 5) ^ result) % 16_777_216;
    result = ((result << 11) ^ result) % 16_777_216;
    return result;
}

fn part1(file: File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader  = buffered_reader.reader();
    const stat = try file.stat();

    var sum: usize = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        var secret = try std.fmt.parseInt(usize, line, 10);
        var i: usize = 0;
        while (i < 2000) : (i += 1) secret = findSecretNumber(secret);
        sum += secret;
    }

    return sum;
}

fn part2(file: File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader  = buffered_reader.reader();
    const stat = try file.stat();

    var sum: usize = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        var secret = try std.fmt.parseInt(usize, line, 10);
        var changes: [1999]i64 = undefined;

        var i: usize = 0;
        while (i < 2000) : (i += 1) {
            const new = findSecretNumber(secret);
            changes[i] = @as(i64, @intCast(new % 10)) - @as(i64, @intCast(secret % 10));
            secret = new;
        }
        sum += secret;
    }

    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    const filename = args.next() orelse return error.FailedToOpenFile;
    {
        const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer file.close();
        std.debug.print("Part 1: {}\n", .{try part1(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day22/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(37_327_623, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day22/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(23, result);
}
