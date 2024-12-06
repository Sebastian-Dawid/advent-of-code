const std = @import("std");
const Allocator = std.mem.Allocator;

const Map = struct {
    const Direction = enum(u64) {
        UP = 0,
        RIGHT = 1,
        DOWN = 2,
        LEFT = 3,
        fn advance(self: @This()) @This() {
            switch (self) {
                Direction.UP => return Direction.RIGHT,
                Direction.RIGHT => return Direction.DOWN,
                Direction.DOWN => return Direction.LEFT,
                Direction.LEFT => return Direction.UP,
            }
        }
    };
    const Position = struct { x: u64, y: u64 };
    const Guard = struct { pos: Position, dir: Direction };
    allocator: Allocator,
    obstacles: std.ArrayList(Position),
    width: u64,
    height: u64,
    guard: Guard,

    fn init(allocator: Allocator) @This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.obstacles = std.ArrayList(Position).init(allocator);
        self.width = 0;
        self.height = 0;
        return self;
    }
    fn deinit(self: *@This()) void {
        self.obstacles.deinit();
    }

    fn step(self: *@This()) bool {
        switch (self.guard.dir) {
            Direction.UP => self.guard.pos.y -= 1,
            Direction.RIGHT => self.guard.pos.x += 1,
            Direction.DOWN => self.guard.pos.y += 1,
            Direction.LEFT => self.guard.pos.x -= 1,
        }
        if (cond: {
            for (self.obstacles.items) |o| {
                if (o.x == self.guard.pos.x and o.y == self.guard.pos.y) break :cond true;
            }
            break :cond false;
        }) {
            switch (self.guard.dir) {
                Direction.UP => self.guard.pos.y += 1,
                Direction.RIGHT => self.guard.pos.x -= 1,
                Direction.DOWN => self.guard.pos.y -= 1,
                Direction.LEFT => self.guard.pos.x += 1,
            }
            self.guard.dir = self.guard.dir.advance();
        }
        if (self.guard.pos.x >= self.width or self.guard.pos.y >= self.height)
            return false;
        return true;
    }

    fn print(self: *const @This()) void {
        var i: u64 = 0;
        while (i < self.height) : (i += 1) {
            var j: u64 = 0;
            while (j < self.width) : (j += 1) {
                if (self.guard.pos.x == j and self.guard.pos.y == i) {
                    switch (self.guard.dir) {
                        Direction.UP => std.debug.print("^", .{}),
                        Direction.RIGHT => std.debug.print(">", .{}),
                        Direction.DOWN => std.debug.print("v", .{}),
                        Direction.LEFT => std.debug.print("<", .{}),
                    }
                    continue;
                }
                for (self.obstacles.items) |o| {
                    if (o.x == j and o.y == i) {
                        std.debug.print("#", .{});
                        break;
                    }
                } else {
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }
};

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    const stat = try file.stat();

    var map = Map.init(allocator);
    defer map.deinit();

    var i: u64 = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| : (i += 1) {
        defer allocator.free(line);
        if (i == 0)
            map.width = line.len;
        for (line, 0..) |c, j| {
            switch (c) {
                '#' => try map.obstacles.append(.{ .x = j, .y = i }),
                '^' => map.guard = .{ .pos = .{ .x = j, .y = i }, .dir = Map.Direction.UP },
                '>' => map.guard = .{ .pos = .{ .x = j, .y = i }, .dir = Map.Direction.RIGHT },
                'v' => map.guard = .{ .pos = .{ .x = j, .y = i }, .dir = Map.Direction.DOWN },
                '<' => map.guard = .{ .pos = .{ .x = j, .y = i }, .dir = Map.Direction.LEFT },
                else => {},
            }
        }
    }
    map.height = i;

    var visited = std.AutoHashMap(Map.Position, u64).init(allocator);
    defer visited.deinit();
    try visited.put(map.guard.pos, 1);
    while (map.step()) {
        _ = try visited.getOrPutValue(map.guard.pos, 1);
        //std.debug.print("===\n", .{});
        //map.print();
    }

    var sum: u64 = 0;
    var it = visited.valueIterator();
    while (it.next()) |v| sum += v.*;

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
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day06/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(41, result);
}
