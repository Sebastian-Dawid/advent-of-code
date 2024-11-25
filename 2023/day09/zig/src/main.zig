const std = @import("std");

const sequence_t = struct {
    values: [32]i64,
    length: usize,

    fn subsequence(self: *sequence_t) sequence_t {
        var result: sequence_t = undefined;
        result.length = 0;
        for (1..self.length) |i| {
            result.values[result.length] = self.values[i] - self.values[i - 1];
            result.length += 1;
        }
        return result;
    }

    fn is_zero(self: *sequence_t) bool {
        for (0..self.length) |i| {
            if (self.values[i] != 0) return false;
        }
        return true;
    }
};

var sequences: [200]sequence_t = undefined;
var sequence_count: usize = 0;

pub fn get_sequences(filename: []const u8) !void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var nums = std.mem.splitAny(u8, line, " ");
        var idx: usize = 0;
        while (nums.next()) |num| {
            sequences[sequence_count].values[idx] = try std.fmt.parseInt(i64, num, 10);
            idx += 1;
        }
        sequences[sequence_count].length = idx;
        sequence_count += 1;
    }
}

pub fn part_1() i64 {
    var sum: i64 = 0;
    for (0..sequence_count) |i| {
        var idx: usize = 0;
        var subs: [20]sequence_t = undefined;
        subs[0] = sequences[i];
        while (!subs[idx].is_zero()) : (idx += 1) {
            subs[idx + 1] = subs[idx].subsequence();
        }

        var val: i64 = 0;
        var j: usize = idx;
        while (j > 0) : (j -= 1) {
            val += subs[j-1].values[subs[j-1].length - 1];
        }
        sum += val;
    }
    return sum;
}

pub fn part_2() i64 {
    var sum: i64 = 0;
    for (0..sequence_count) |i| {
        var idx: usize = 0;
        var subs: [20]sequence_t = undefined;
        subs[0] = sequences[i];
        while (!subs[idx].is_zero()) : (idx += 1) {
            subs[idx + 1] = subs[idx].subsequence();
        }

        var val: i64 = 0;
        var j: usize = idx;
        while (j > 0) : (j -= 1) {
            val = subs[j-1].values[0] - val;
        }
        sum += val;
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
    
    try get_sequences(filename);

    const part_1_result: i64 = part_1();
    try stdout.print("Part 1: {}\n", .{part_1_result});
    
    const part_2_result: i64 = part_2();
    try stdout.print("Part 2: {}\n", .{part_2_result});

    try bw.flush(); // don't forget to flush!
}

test "Part 1" {
    const expected: i64 = 114;
    const filename: []const u8 = "../test.txt";
    try get_sequences(filename);
    const actual: i64 = part_1();
    try std.testing.expectEqual(expected, actual);
}

test "Part 2" {
    const expected: i64 = 2;
    const filename: []const u8 = "../test.txt";
    if (sequence_count == 0) {
        try get_sequences(filename);
    }
    const actual: i64 = part_2();
    try std.testing.expectEqual(expected, actual);
}
