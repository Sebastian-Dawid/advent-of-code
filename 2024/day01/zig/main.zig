const std = @import("std");
const Allocator = std.mem.Allocator;

fn parse(file: std.fs.File, allocator: Allocator) !struct { left: []u64, right: []u64 }
{
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    var left = std.ArrayList(u64).init(allocator);
    defer left.deinit();
    var right = std.ArrayList(u64).init(allocator);
    defer right.deinit();

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);
        var nums = std.mem.splitAny(u8, line, " ");
        var first = true;
        while (nums.next()) |num|
        {
            if (num.len == 0) continue;
            if (first) {
                try left.append(try std.fmt.parseInt(u64, num, 10));
                first = false;
            } else {
                try right.append(try std.fmt.parseInt(u64, num, 10));
            }
        }
    }
    return .{ .left = try left.toOwnedSlice(), .right = try right.toOwnedSlice(), };
}

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    const data = try parse(file, allocator);
    defer allocator.free(data.left);
    defer allocator.free(data.right);

    std.mem.sort(u64, data.left, {}, comptime std.sort.asc(u64));
    std.mem.sort(u64, data.right, {}, comptime std.sort.asc(u64));
    var index: u64 = 0;
    var sum: u64 = 0;
    while (index < data.left.len) : (index += 1) {
        if (data.left[index] > data.right[index]) {
            sum +=  data.left[index] - data.right[index];
        } else {
            sum += data.right[index] - data.left[index];
        }
    }
    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    const data = try parse(file, allocator);
    defer allocator.free(data.left);
    defer allocator.free(data.right);

    var i: u64 = 0;
    var sum: u64 = 0;
    while (i < data.left.len) : (i += 1) {
        var j: u64 = 0;
        while (j < data.right.len) : (j += 1) {
            if (data.right[j] == data.left[i]) {
                sum += data.left[i];
            }
        }
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    const filename = args.next() orelse return error.NoFileGiven;
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
        defer file.close();
        std.debug.print("Part 1: {}\n", .{ try part1(file, allocator) });
    }
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
        defer file.close();
        std.debug.print("Part 2: {}\n", .{ try part2(file, allocator) });
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day01/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(result, 11);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day01/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();

    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(result, 31);
}
