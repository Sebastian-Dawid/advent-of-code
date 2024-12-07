const std = @import("std");
const Allocator = std.mem.Allocator;

fn test_computation(comptime with_concat: bool, current: u64, others: []const u64) bool {
    if (others.len == 1) return others[0] == current;

    if (current > others[others.len - 1]) {
        if (test_computation(with_concat, current - others[others.len - 1], others[0..(others.len - 1)])) return true;
    }
    if (current % others[others.len - 1] == 0) {
        if (test_computation(with_concat, current / others[others.len - 1], others[0..(others.len - 1)])) return true;
    }
    if (with_concat) {
        const modulo = std.math.powi(u64, 10, @as(u64, @intFromFloat(std.math.floor(std.math.log10(@as(f64, @floatFromInt(others[others.len - 1])))) + 1))) catch unreachable;
        if (current % modulo == others[others.len - 1]) {
            if (test_computation(with_concat, (current - others[others.len - 1])/modulo, others[0..(others.len - 1)])) return true;
        }
    }

    return false;
}

test "copmutation 1" {
    const slice = [_]u64{ 10, 19 };
    try std.testing.expect(test_computation(false, 190, &slice));
}

test "copmutation 2" {
    const slice = [_]u64{ 81, 40, 27 };
    try std.testing.expect(test_computation(false, 3267, &slice));
}

test "copmutation 3" {
    const slice = [_]u64{ 11, 6, 16, 20 };
    try std.testing.expect(test_computation(false, 292, &slice));
}

test "copmutation 4" {
    const slice = [_]u64{ 6, 8, 6, 15 };
    try std.testing.expect(!test_computation(false, 7290, &slice));
}

test "copmutation 5" {
    const slice = [_]u64{ 16, 10, 13 };
    try std.testing.expect(!test_computation(false, 161011, &slice));
}

test "computation 6" {
    const slice = [_]u64{ 15, 6 };
    try std.testing.expect(test_computation(true, 156, &slice));
}

test "computation 7" {
    const slice = [_]u64{ 6, 8, 6, 15 };
    try std.testing.expect(test_computation(true, 7290, &slice));
}

test "computation 8" {
    const slice = [_]u64{ 17, 8, 14 };
    try std.testing.expect(test_computation(true, 192, &slice));
}

test "computation 9" {
    const slice = [_]u64{ 29, 983, 1, 6, 5, 9, 2, 465 };
    try std.testing.expect(test_computation(true, 423814950, &slice));
}

fn part(comptime with_concat: bool, file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    var sum: u64 = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        

        var outer_split = std.mem.splitAny(u8, line, ":");
        const total = if (outer_split.next()) |n| try std.fmt.parseInt(u64, n, 10) else continue;
        const slice = blk: {
            var arr = std.ArrayList(u64).init(allocator);
            defer arr.deinit();
            if (outer_split.next()) |s| {
                var inner_split = std.mem.splitAny(u8, s[1..], " ");
                while (inner_split.next()) |n| {
                    try arr.append(try std.fmt.parseInt(u64, n, 10));
                }
                break :blk try arr.toOwnedSlice();
            }
            else continue;
        };
        defer allocator.free(slice);

        if (test_computation(with_concat, total, slice)) {
            sum += total;
        }
    }

    return sum;
}

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    return try part(false, file, allocator);
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    return try part(true, file, allocator);
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
        std.debug.print("Part 1: {}\n", .{try part1(file, allocator)});
    }
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
        defer file.close();
        std.debug.print("Part 2: {}\n", .{try part2(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day07/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(3749, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day07/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(11387, result);
}
