const std = @import("std");
const ArrayList = std.ArrayList;

pub fn part_1(filename: []const u8) !u32 {
    var sum: u32 = 0;
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var rem = std.mem.split(u8, line, ": ");
        _ = rem.next().?;
        var groups = std.mem.split(u8, rem.next().?, " | ");
        var winning = ArrayList(u32).init(allocator);
        defer winning.deinit();

        var winners: u32 = 0;

        var nums = std.mem.split(u8, groups.next().?, " ");
        while (nums.next()) |number| {
            try winning.append(std.fmt.parseUnsigned(u32, number, 10) catch continue);
        }
        nums = std.mem.split(u8, groups.next().?, " ");
        while (nums.next()) |number| {
            const val: u32 = std.fmt.parseUnsigned(u32, number, 10) catch continue;
            for (winning.items) |value| {
                if (val == value) {
                    winners += 1;
                    break;
                }
            }
        }

        if (winners > 0) {
            sum += std.math.pow(u32, 2, winners - 1);
        }
    }

    return sum;
}

pub fn part_2(filename: []const u8) !u32 {
    var sum: u32 = 0;
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var repetitions: ArrayList(u32) = ArrayList(u32).init(allocator);
    defer repetitions.deinit();

    var scratchcard: u32 = 0;
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (repetitions.items.len <= scratchcard) {
            try repetitions.append(1);
        } else {
            repetitions.items[scratchcard] += 1;
        }

        var rem = std.mem.split(u8, line, ": ");
        _ = rem.next().?;
        var groups = std.mem.split(u8, rem.next().?, " | ");
        var winning = ArrayList(u32).init(allocator);
        defer winning.deinit();

        var winners: u32 = 0;

        var nums = std.mem.split(u8, groups.next().?, " ");
        while (nums.next()) |number| {
            try winning.append(std.fmt.parseUnsigned(u32, number, 10) catch continue);
        }
        nums = std.mem.split(u8, groups.next().?, " ");
        while (nums.next()) |number| {
            const val: u32 = std.fmt.parseUnsigned(u32, number, 10) catch continue;
            for (winning.items) |value| {
                if (val == value) {
                    winners += 1;
                    break;
                }
            }
        }

        for (0..repetitions.items[scratchcard]) |_| {
            if (winners > 0) {
                for (1..winners+1) |j| {
                    if (repetitions.items.len <= scratchcard + j) {
                        try repetitions.append(1);
                    } else {
                        repetitions.items[scratchcard + j] += 1;
                    }
                }
            }
        }
        scratchcard += 1;
    }


    for (repetitions.items) |values| {
        sum += values;
    }

    return sum;
}

pub fn main() !void {

    var args = std.process.args();
    _ = args.skip();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const filename = args.next() orelse {
        std.debug.print("Usage: <prog> <filename>\n", .{});
        std.os.exit(1);
    };
    
    const part_1_result: u32 = try part_1(filename);
    try stdout.print("Part 1: {}\n", .{part_1_result});
    
    const part_2_result: u32 = try part_2(filename);
    try stdout.print("Part 2: {}\n", .{part_2_result});

    try bw.flush(); // don't forget to flush!
}

test "Part 1" {
    const expected: u32 = 13;
    const filename: []const u8 = "../test.txt";
    const actual: u32 = try part_1(filename);
    try std.testing.expectEqual(expected, actual);
}

test "Part 2" {
    const expected: u32 = 30;
    const filename: []const u8 = "../test.txt";
    const actual: u32 = try part_2(filename);
    try std.testing.expectEqual(expected, actual);
}
