const std = @import("std");

const mapping_t = struct {
    dst_start: usize,
    src_start: usize,
    length: usize,

    fn in_src_range(self: *mapping_t, value: usize) bool {
        return self.src_start <= value and value < (self.src_start + self.length);
    }
    fn in_dst_range(self: *mapping_t, value: usize) bool {
        return self.dst_start <= value and value < (self.dst_start + self.length);
    }
};

const table_t = std.ArrayList(mapping_t);

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var seeds: [20]usize = [20]usize{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
var seed_count: usize = 0;
var tables = std.ArrayList(table_t).init(allocator);

pub fn find_mapped_value(table: *const table_t, value: usize) usize {
    for (0..table.items.len) |i| {
        if (table.items[i].in_src_range(value)) {
            return table.items[i].dst_start + (value - table.items[i].src_start);
        }        
    }
    return value;
}

pub fn find_unmapped_value(table: *const table_t, value: usize) usize {
    for (0..table.items.len) |i| {
        if (table.items[i].in_dst_range(value)) {
            return table.items[i].src_start + (value - table.items[i].dst_start);
        }        
    }
    return value;
}

pub fn is_valid_seed(value: usize) bool {
    var idx:usize = 0;
    while (idx < seed_count) : (idx += 2) {
        if (seeds[idx] <= value and value < seeds[idx] + seeds[idx + 1]) return true;
    }
    return false;
}

pub fn generate_tables(filename: []const u8) !void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    

    var buf: [1024]u8 = undefined;

    const ln = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var rem = std.mem.split(u8, ln.?, ": ");
    _ = rem.next().?;
    var nums = std.mem.split(u8, rem.next().?, " ");
    while (nums.next()) |num| {
        seeds[seed_count] = try std.fmt.parseUnsigned(usize, num, 10);
        seed_count += 1;
    }
    
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len < 2) continue;
        if (std.mem.eql(u8, line[(line.len - 4)..(line.len - 1)], "map")) {
            try tables.append(table_t.init(allocator));
            continue;
        }
        if (tables.items.len == 0) continue;

        var num_it = std.mem.splitAny(u8, line, " ");
        const mapping = mapping_t{
            .dst_start = try std.fmt.parseUnsigned(usize, num_it.next().?, 10),
            .src_start = try std.fmt.parseUnsigned(usize, num_it.next().?, 10),
            .length = try std.fmt.parseUnsigned(usize, num_it.next().?, 10)
        };
        try tables.items[tables.items.len - 1].append(mapping);
    }
}

pub fn part_1() usize {
    var min: usize = std.math.maxInt(usize);

    for (0..seed_count) |idx| {
        var val: usize = seeds[idx];
        for (tables.items) |table| {
            val = find_mapped_value(&table, val);
        }
        min = if (val < min) val else min;
    }

    return min;
}

pub fn part_2() usize {
    var location: usize = 0;
    var seed: usize = 0;

    for (0..tables.items.len) |idx| {
        seed = find_unmapped_value(&tables.items[6 - idx], seed);
    }

    while (is_valid_seed(seed) == false) {
        seed = location;
        for (0..tables.items.len) |idx| {
            seed = find_unmapped_value(&tables.items[6 - idx], seed);
        }
        location += 1;
    }

    return location - 1;
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
    
    try generate_tables(filename);

    const part_1_result: usize = part_1();
    try stdout.print("Part 1: {}\n", .{part_1_result});
    
    const part_2_result: usize = part_2();
    try stdout.print("Part 2: {}\n", .{part_2_result});

    try bw.flush(); // don't forget to flush!
}

test "Part 1" {
    const expected: usize = 35;
    const filename: []const u8 = "../test.txt";
    try generate_tables(filename);
    const actual: usize = part_1();
    try std.testing.expectEqual(expected, actual);
}

test "Part 2" {
    const expected: usize = 46;
    if (tables.items.len == 0) {
        const filename: []const u8 = "../test.txt";
        try generate_tables(filename);
    }
    const actual: usize = part_2();
    try std.testing.expectEqual(expected, actual);
}
