const std = @import("std");

pub fn part_1(filename: []const u8) !u32 {
    var sum: u32 = 0;
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var first: u8 = 0x30;
        var last: u8 = 0x30;
        var first_found: bool = false;
        for (line) |char| {
            if ((char < 0x30) or (char > 0x39)) continue;
            if (!first_found) {
                first = char;
                first_found = true;
            }
            last = char;
        }
        sum += (first - 0x30) * 10;
        sum += last - 0x30;
    }

    return sum;
}

pub fn check_written_digit(word: []const u8, remaining_length: usize) u8 {
    if (remaining_length < 3) return 0;
    if (std.mem.eql(u8, word[0..3], "one")) return 0x31;
    if (std.mem.eql(u8, word[0..3], "two")) return 0x32;
    if (std.mem.eql(u8, word[0..3], "six")) return 0x36;
    if (remaining_length < 4) return 0;
    if (std.mem.eql(u8, word[0..4], "four")) return 0x34;
    if (std.mem.eql(u8, word[0..4], "five")) return 0x35;
    if (std.mem.eql(u8, word[0..4], "nine")) return 0x39;
    if (remaining_length < 5) return 0;
    if (std.mem.eql(u8, word[0..5], "three")) return 0x33;
    if (std.mem.eql(u8, word[0..5], "seven")) return 0x37;
    if (std.mem.eql(u8, word[0..5], "eight")) return 0x38;
    return 0;
}

pub fn part_2(filename: []const u8) !u32 {
    var sum: u32 = 0;
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var first: u8 = 0x30;
        var last: u8 = 0x30;
        var first_found: bool = false;
        var idx: u32 = 0;
        while (idx < line.len) : (idx += 1) {
            var char: u8 = line[idx];
            if ((char < 0x30) or (char > 0x39)) {
                char = check_written_digit(line[idx..line.len], line.len - idx);
                if (char == 0)
                {
                    continue;
                }
            }
            if (!first_found) {
                first = char;
                first_found = true;
            }
            last = char;
        }
        sum += (first - 0x30) * 10;
        sum += last - 0x30;
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
    const expected: u32 = 142;
    const filename: []const u8 = "../test.txt";
    const actual: u32 = try part_1(filename);
    try std.testing.expectEqual(expected, actual);
}

test "Part 2" {
    const expected: u32 = 281;
    const filename: []const u8 = "../test_2.txt";
    const actual: u32 = try part_2(filename);
    try std.testing.expectEqual(expected, actual);
}
