const std = @import("std");
const Allocator = std.mem.Allocator;

const Map = struct {
    const Vec2 = struct {
        x: i64,
        y: i64,
        fn add(self: @This(), other: @This()) @This() {
            return .{ .x = self.x + other.x, .y = self.y + other.y };
        }
        fn sub(self: @This(), other: @This()) @This() {
            return .{ .x = self.x - other.x, .y = self.y - other.y };
        }
        fn scale(self: @This(), lambda: i64) @This() {
            return .{ .x = lambda * self.x, .y = lambda * self.y };
        }
    };
    const Antenna = struct {
        type: u8,
        pos: Vec2,
    };
    allocator: Allocator,
    width: u64,
    height: u64,
    antennas: std.ArrayList(Antenna),
    antinodes: std.AutoHashMap(Vec2, u1),

    fn init(allocator: Allocator) @This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.antennas = std.ArrayList(Antenna).init(allocator);
        self.antinodes = std.AutoHashMap(Vec2, u1).init(allocator);
        self.width = 0;
        self.height = 0;
        return self;
    }
    fn deinit(self: *@This()) void {
        self.antennas.deinit();
        self.antinodes.deinit();
    }
};

fn parse_map(file: std.fs.File, allocator: Allocator) !Map {
    var map = Map.init(allocator);

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    var i: i64 = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        if (i == 0) map.width = line.len;
        for (line, 0..) |c, j| {
            if (c != '.') {
                try map.antennas.append(.{ .type = c, .pos = .{ .x = @intCast(j), .y = i } });
            }
        }
        i += 1;
    }
    map.height = @intCast(i);

    return map;
}

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var map = try parse_map(file, allocator);
    defer map.deinit();

    for (map.antennas.items, 0..) |a, i| {
        for (map.antennas.items, 0..) |b, j| {
            if (i == j) continue;
            if (a.type != b.type) continue;
            const pos = a.pos.add(b.pos.sub(a.pos).scale(2));
            if (pos.x < 0 or pos.y < 0 or pos.x >= map.width or pos.y >= map.height) continue;
            try map.antinodes.put(pos, 1);
        }
    }

    var sum: u64 = 0;
    var it = map.antinodes.valueIterator();
    while (it.next()) |v| sum += v.*;

    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    _ = allocator; // autofix
    _ = file; // autofix
    return 0;
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
    const file = std.fs.cwd().openFile("../../../inputs/2024/day08/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(14, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day07/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(11387, result);
}
