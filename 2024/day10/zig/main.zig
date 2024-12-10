const std = @import("std");
const Allocator = std.mem.Allocator;

const Map = struct {
    const Position = struct {
        x: i64,
        y: i64,
        fn add(self: @This(), other: @This()) @This() {
            return .{ .x = self.x + other.x, .y = self.y + other.y };
        }
    };
    allocator: Allocator,
    width: u64,
    height: u64,
    map: std.ArrayList(u8),
    marked: std.AutoHashMap(Position, u1),
    trailheads: std.ArrayList(Position),

    fn init(file: std.fs.File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.width = 0;
        self.height = 0;
        self.allocator = allocator;
        self.map = std.ArrayList(u8).init(self.allocator);
        self.marked = std.AutoHashMap(Position, u1).init(self.allocator);
        self.trailheads = std.ArrayList(Position).init(self.allocator);

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();
        const stat = try file.stat();
        var i: u64 = 0;
        while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
            defer allocator.free(line);
            if (i == 0) self.width = line.len;
            for (line, 0..) |c, j| {
                if (c == 0x30) try self.trailheads.append(.{ .x = @intCast(j), .y = @intCast(i) });
                try self.map.append(c - 0x30);
            }
            i += 1;
        }
        self.height = i;
        return self;
    }

    fn deinit(self: *@This()) void {
        self.map.deinit();
        self.marked.deinit();
        self.trailheads.deinit();
    }

    fn clear(self: *@This()) void {
        self.marked.clearAndFree();
    }

    fn at(self: *@This(), position: Position) u8 {
        return self.map.items[@as(u64, @intCast(position.y)) * self.width + @as(u64, @intCast(position.x))];
    }

    fn walkPaths(self: *@This(), comptime with_marking: bool, height: u8, position: Position) !u64 {
        if (with_marking) try self.marked.put(position, 1);
        if (height == 9) return 1;
        var sum: u64 = 0;
        if (position.x > 0) {
            const pos = position.add(.{.x = -1, .y = 0});
            if (self.marked.get(pos) == null and self.at(pos) == height + 1) {
                sum += try self.walkPaths(with_marking, self.at(pos), pos);
            }
        }
        if (position.y > 0) {
            const pos = position.add(.{.x = 0, .y = -1});
            if (self.marked.get(pos) == null and self.at(pos) == height + 1) {
                sum += try self.walkPaths(with_marking, self.at(pos), pos);
            }
        }
        if (position.x < self.width - 1) {
            const pos = position.add(.{.x = 1, .y = 0});
            if (self.marked.get(pos) == null and self.at(pos) == height + 1) {
                sum += try self.walkPaths(with_marking, self.at(pos), pos);
            }
        }
        if (position.y < self.height - 1) {
            const pos = position.add(.{.x = 0, .y = 1});
            if (self.marked.get(pos) == null and self.at(pos) == height + 1) {
                sum += try self.walkPaths(with_marking, self.at(pos), pos);
            }
        }
        return sum;
    }
};

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var map = try Map.init(file, allocator);
    defer map.deinit();

    var sum: u64 = 0;
    for (map.trailheads.items) |p| {
        sum += try map.walkPaths(true, 0, p);
        map.clear();
    }

    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    var map = try Map.init(file, allocator);
    defer map.deinit();

    var sum: u64 = 0;
    for (map.trailheads.items) |p| {
        sum += try map.walkPaths(false, 0, p);
        map.clear();
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
        std.debug.print("Part 1: {}\n", .{try part1(file, allocator)});
    }
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FileNotFound;
        defer file.close();
        std.debug.print("Part 2: {}\n", .{try part2(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day10/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(36, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day10/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(81, result);
}
