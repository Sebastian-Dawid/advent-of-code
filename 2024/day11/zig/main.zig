const std = @import("std");
const Allocator = std.mem.Allocator;

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    var list = std.ArrayList(u64).init(allocator);
    defer list.deinit();

    const input = (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) orelse return error.EmptyFile;
    defer allocator.free(input);

    var split = std.mem.splitAny(u8, input, " ");
    while (split.next()) |num| {
        try list.append(try std.fmt.parseInt(u64, num, 10));
    }

    var count: u64 = 0;
    while (count < 25) : (count += 1) {
        var i: u64 = 0;
        while (i < list.items.len) : (i += 1) {
            if (list.items[i] == 0) {
                list.items[i] = 1;
            } else if ((std.math.log10_int(list.items[i]) + 1) % 2 == 0) {
                const copy = list.items[i];
                list.items[i] = copy / try std.math.powi(u64, 10, (std.math.log10_int(copy)+1)/2);
                try list.insert(i+1, copy % try std.math.powi(u64, 10, (std.math.log10_int(copy)+1)/2));
                i += 1;
            } else {
                list.items[i] *= 2024;
            }
        }
    }

    return list.items.len;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    _ = allocator; // autofix
    _ = file; // autofix
    return 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
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
    const file = std.fs.cwd().openFile("../../../inputs/2024/day11/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(55312, result);
}
