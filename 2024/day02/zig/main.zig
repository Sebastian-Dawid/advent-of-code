const std = @import("std");
const Allocator = std.mem.Allocator;

fn part1(file: std.fs.File) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    var buffer: [1024]u8 = undefined;
    var sum: u64 = 0;
    outer: while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var nums = std.mem.splitAny(u8, line, " ");
        const first = try std.fmt.parseInt(u64, nums.next().?, 10);
        var last = try std.fmt.parseInt(u64, nums.next().?, 10);

        const acsending = first < last;
        if (acsending) {
            if (0 >= last - first or last - first >= 4) {
                continue :outer;
            }
        } else {
            if (0 >= first - last or first - last >= 4) {
                continue :outer;
            }
        }

        while (nums.next()) |num| {
            const n = try std.fmt.parseInt(u64, num, 10);
            if (acsending != (last < n)) {
                continue :outer;
            }
            if (acsending) {
                if (0 >= n - last or n - last >= 4) {
                    continue :outer;
                }
            } else {
                if (0 >= last - n or last - n >= 4) {
                    continue :outer;
                }
            }
            last = n;
        }
        sum += 1;
    }
    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    var buffer: [1024]u8 = undefined;
    var sum: u64 = 0;
    var unsafe = std.ArrayList([]u64).init(allocator);
    defer {
        for (unsafe.items) |item| allocator.free(item);
        unsafe.deinit();
    }

    outer: while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var nums = std.mem.splitAny(u8, line, " ");
        var list = std.ArrayList(u64).init(allocator);
        defer list.deinit();
        while (nums.next()) |num| {
            try list.append(try std.fmt.parseInt(u64, num, 10));
        }
        var i: u64 = 1;
        var last = list.items[0];
        const acsending = last < list.items[1];
        while (i < list.items.len) : (i += 1) {
            const n = list.items[i];
            if (acsending != (last < n)) {
                try unsafe.append(try list.toOwnedSlice());
                continue :outer;
            }
            if (acsending) {
                if (0 >= n - last or n - last >= 4) {
                    try unsafe.append(try list.toOwnedSlice());
                    continue :outer;
                }
            } else {
                if (0 >= last - n or last - n >= 4) {
                    try unsafe.append(try list.toOwnedSlice());
                    continue :outer;
                }
            }
            last = n;
        }
        sum += 1;
    }

    outer: for (unsafe.items) |list| {
        var i: u64 = 0;
        while (i < list.len) : (i += 1) {
            var j: u64 = 1;
            var last: u64 = list[0];
            var acsending = last < list[1];
            if (i == 0) {
                j = 2;
                last = list[1];
                acsending = last < list[2];
            } else if (i == 1) {
                j = 2;
                last = list[0];
                acsending = last < list[2];
            }
            var brk = false;
            inner: while (j < list.len) : (j += 1) {
                const n = list[j];
                if (i != j) {
                    if (acsending != (last < n)) {
                        brk = true;
                        break :inner;
                    }
                    if (acsending) {
                        if (0 >= n - last or n - last >= 4) {
                            brk = true;
                            break :inner;
                        }
                    } else {
                        if (0 >= last - n or last - n >= 4) {
                            brk = true;
                            break :inner;
                        }
                    }
                    last = n;
                }
            }
            if (!brk) {
                sum += 1;
                continue :outer;
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
        std.debug.print("Part 1: {}\n", .{try part1(file)});
    }
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
        defer file.close();
        std.debug.print("Part 2: {}\n", .{try part2(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day02/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const result = part1(file);
    try std.testing.expectEqual(2, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day02/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(4, result);
}
