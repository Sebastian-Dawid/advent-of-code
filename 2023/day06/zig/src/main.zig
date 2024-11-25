const std = @import("std");

pub fn find_num_greater(t: usize, d: usize) usize {
    var num: usize = 0;
    for (1..t) |i| {
        if (i * (t - i) > d) num += 1;
    }
    return num;
}

pub fn part_1(filename: []const u8) !usize {
    var prod: usize = 1;
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    
    var buf: [1024]u8 = undefined;
    var line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;
    var rem = std.mem.split(u8, line, ":");
    _ = rem.next();
    var nums = std.mem.split(u8, rem.next().?, " ");

    var times: [4]usize = [4]usize{0, 0, 0, 0};
    var value_count: usize = 0;

    var idx: usize = 0;
    while (nums.next()) |num| {
        const val = std.fmt.parseUnsigned(usize, num, 10) catch continue;
        times[idx] = val;
        idx += 1;
        value_count += 1;
    }
    
    line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;
    rem = std.mem.split(u8, line, ":");
    _ = rem.next();
    nums = std.mem.split(u8, rem.next().?, " ");
    var dists: [4]usize = [4]usize{0, 0, 0, 0};
    idx = 0;
    while (nums.next()) |num| {
        const val = std.fmt.parseUnsigned(usize, num, 10) catch continue;
        dists[idx] = val;
        idx += 1;
    }

    for (0..value_count) |i| {
        prod *= find_num_greater(times[i], dists[i]);
    }

    return prod;
}

pub fn part_2(filename: []const u8) !usize {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    
    var buf: [1024]u8 = undefined;
    var line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;
    var rem = std.mem.split(u8, line, ":");
    _ = rem.next();

    var numbuf: [64]u8 = undefined;
    var nums = std.mem.split(u8, rem.next().?, " ");
    var idx: usize = 0;
    while (nums.next()) |num| {
        if (num.len < 1) continue;
        for (0..num.len) |i| {
            numbuf[idx] = num[i];
            idx += 1;
        }
    }
    const time = try std.fmt.parseUnsigned(usize, numbuf[0..idx], 10);

    line = (try in_stream.readUntilDelimiterOrEof(&buf, '\n')).?;
    rem = std.mem.split(u8, line, ":");
    _ = rem.next();

    numbuf = undefined;
    nums = std.mem.split(u8, rem.next().?, " ");
    idx = 0;
    while (nums.next()) |num| {
        if (num.len < 1) continue;
        for (0..num.len) |i| {
            numbuf[idx] = num[i];
            idx += 1;
        }
    }
    const dist = try std.fmt.parseUnsigned(usize, numbuf[0..idx], 10);
    
    return find_num_greater(time, dist);
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
    
    const part_1_result: usize = try part_1(filename);
    try stdout.print("Part 1: {}\n", .{part_1_result});
    
    const part_2_result: usize = try part_2(filename);
    try stdout.print("Part 2: {}\n", .{part_2_result});

    try bw.flush(); // don't forget to flush!
}

test "Part 1" {
    const expected: usize = 288;
    const filename: []const u8 = "../test.txt";
    const actual: usize = try part_1(filename);
    try std.testing.expectEqual(expected, actual);
}

test "Part 2" {
    const expected: usize = 71503;
    const filename: []const u8 = "../test.txt";
    const actual: usize = try part_2(filename);
    try std.testing.expectEqual(expected, actual);
}
