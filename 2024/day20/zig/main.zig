const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Solver = struct {
    const Direction = enum {
        UP,
        RIGHT,
        DOWN,
        LEFT,
        const ALL = [_]@This(){ .UP, .RIGHT, .DOWN, .LEFT };
    };
    const Tile = struct {
        variant: enum { PATH, WALL } = .WALL,
        index: ?usize = null,
    };

    const Vec2 = struct {
        x: i64,
        y: i64,

        fn fromDirection(direction: Direction) @This() {
            return switch (direction) {
                .UP => .{ .x = 0, .y = 1 },
                .RIGHT => .{ .x = 1, .y = 0 },
                .DOWN => .{ .x = 0, .y = -1 },
                .LEFT => .{ .x = -1, .y = 0 },
            };
        }

        fn add(self: @This(), other: @This()) @This() {
            return .{ .x = self.x + other.x, .y = self.y + other.y };
        }

        fn manhatten(self: @This(), other: @This()) u64 {
            return @abs(self.x - other.x) + @abs(self.y - other.y);
        }

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try writer.print("({d: >7} {d: >7})", .{ self.x, self.y });
        }
    };
    allocator: Allocator,
    map: []Vec2,
    start: Vec2,
    end: Vec2,
    width: usize,
    height: usize,

    fn init(file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();
        const stat = try file.stat();

        var map = std.AutoArrayHashMap(Vec2, Tile).init(allocator);
        defer map.deinit();

        var width: usize = 0;
        var height: usize = 0;
        while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
            defer allocator.free(line);
            if (height == 0) width = line.len;
            for (line, 0..) |c, x| {
                const p = Vec2{ .x = @intCast(x), .y = @intCast(height) };
                switch (c) {
                    'S', 'E', '.' => {
                        if (c == 'S') self.start = p;
                        if (c == 'E') self.end = p;
                        try map.put(p, .{ .variant = .PATH, .index = null });
                    },
                    '#' => {
                        try map.put(p, .{ .variant = .WALL, .index = null });
                    },
                    else => {},
                }
            }
            height += 1;
        }

        var path = std.ArrayList(Vec2).init(allocator);
        defer path.deinit();

        var length: usize = 0;
        var current = self.start;
        while (current.x != self.end.x or current.y != self.end.y) : (length += 1) {
            try path.append(current);
            try map.put(current, .{ .variant = .PATH, .index = length });
            for (Direction.ALL) |dir| {
                if (map.get(current.add(Vec2.fromDirection(dir)))) |next| {
                    if (next.variant == .PATH and next.index == null) {
                        current = current.add(Vec2.fromDirection(dir));
                        break;
                    }
                }
            }
        }
        try path.append(current);
        try map.put(current, .{ .variant = .PATH, .index = length });

        self.map = try path.toOwnedSlice();

        return self;
    }

    fn deinit(self: *@This()) void {
        self.allocator.free(self.map);
    }

    fn find_cheats(self: *const @This(), allocator: Allocator, comptime max_length: usize) !std.AutoArrayHashMap(usize, usize) {
        var result = std.AutoArrayHashMap(usize, usize).init(allocator);

        for (self.map, 0..) |p1, i| {
            for (self.map[(i+1)..], (i+1)..) |p2, j| {
                const manhatten = p1.manhatten(p2);
                if (manhatten > max_length) continue;
                const timesave = j - i - manhatten;
                if (result.getPtr(timesave)) |ptr| {
                    ptr.* += 1;
                } else {
                    try result.put(timesave, 1);
                }
            }
        }

        return result;
    }
};

fn part(file: File, allocator: Allocator, comptime target: usize, comptime max_length: usize) !u64 {
    var solver = try Solver.init(file, allocator);
    defer solver.deinit();

    var r = try solver.find_cheats(allocator, max_length);
    defer r.deinit();

    var sum: u64 = 0;
    for (r.keys()) |k| {
        if (k >= target) sum += r.get(k).?;
    }

    return sum;
}

fn part1(file: File, allocator: Allocator, comptime target: usize) !u64 {
    return try part(file, allocator, target, 2);
}

fn part2(file: File, allocator: Allocator, comptime target: usize) !u64 {
    return try part(file, allocator, target, 20);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();
    const filename = args.next() orelse return error.FailedToOpenFile;
    {
        const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer file.close();
        std.debug.print("Part 1: {}\n", .{try part1(file, allocator, 100)});
    }
    {
        const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer file.close();
        std.debug.print("Part 2: {}\n", .{try part2(file, allocator, 100)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day20/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator, 40);
    try std.testing.expectEqual(2, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day20/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator, 70);
    try std.testing.expectEqual(41, result);
}
