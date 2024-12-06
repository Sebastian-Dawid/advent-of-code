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
    const Position = struct { x: i64, y: i64 };
    const Guard = struct { pos: Position, dir: Direction };
    allocator: Allocator,
    obstacles: std.ArrayList(Position),
    width: u64,
    height: u64,
    guard: Guard,
    guard_initial: Guard,

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

    fn copy(self: *@This()) !@This() {
        var other: @This() = undefined;
        other.allocator = self.allocator;
        other.obstacles = try self.obstacles.clone();
        other.width = self.width;
        other.height = self.height;
        other.guard = self.guard;
        other.guard_initial = self.guard_initial;
        return other;
    }

    fn reset(self: *@This()) void {
        self.guard = self.guard_initial;
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
        if (self.guard.pos.x >= self.width or self.guard.pos.x < 0 or self.guard.pos.y >= self.height or self.guard.pos.y < 0)
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
                '#' => try map.obstacles.append(.{ .x = @intCast(j), .y = @intCast(i) }),
                '^' => map.guard = .{ .pos = .{ .x = @intCast(j), .y = @intCast(i) }, .dir = Map.Direction.UP },
                '>' => map.guard = .{ .pos = .{ .x = @intCast(j), .y = @intCast(i) }, .dir = Map.Direction.RIGHT },
                'v' => map.guard = .{ .pos = .{ .x = @intCast(j), .y = @intCast(i) }, .dir = Map.Direction.DOWN },
                '<' => map.guard = .{ .pos = .{ .x = @intCast(j), .y = @intCast(i) }, .dir = Map.Direction.LEFT },
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

fn check_position(map: *Map, position: Map.Position, count: *u64, mutex: *std.Thread.Mutex) void {
    var _map = map.copy() catch { return; };
    defer _map.deinit();
    _map.obstacles.append(position) catch { return; };
    var visited = std.AutoHashMap(Map.Guard, u64).init(_map.allocator);
    defer visited.deinit();
    visited.put(_map.guard, 1) catch { return; };
    while (_map.step()) {
        const e = visited.getOrPut(_map.guard) catch { return; };
        if (e.found_existing) {
            mutex.lock();
            defer mutex.unlock();
            count.* += 1;
            break;
        } else {
            e.value_ptr.* = 1;
        }
    }
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
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
                '#' => try map.obstacles.append(.{ .x = @intCast(j), .y = @intCast(i) }),
                '^' => map.guard = .{ .pos = .{ .x = @intCast(j), .y = @intCast(i) }, .dir = Map.Direction.UP },
                '>' => map.guard = .{ .pos = .{ .x = @intCast(j), .y = @intCast(i) }, .dir = Map.Direction.RIGHT },
                'v' => map.guard = .{ .pos = .{ .x = @intCast(j), .y = @intCast(i) }, .dir = Map.Direction.DOWN },
                '<' => map.guard = .{ .pos = .{ .x = @intCast(j), .y = @intCast(i) }, .dir = Map.Direction.LEFT },
                else => {},
            }
        }
    }
    map.guard_initial = map.guard;
    map.height = i;

    var visited_normal = std.AutoHashMap(Map.Position, u64).init(allocator);
    defer visited_normal.deinit();
    try visited_normal.put(map.guard.pos, 1);
    while (map.step()) {
        _ = try visited_normal.getOrPutValue(map.guard.pos, 1);
    }
    map.reset();

    var count: u64 = 0;
    var it = visited_normal.keyIterator();
    {
        var mutex = std.Thread.Mutex{};
        var pool: std.Thread.Pool = undefined;
        try pool.init(.{
            .allocator = allocator,
        });
        defer pool.deinit();
        while (it.next()) |k| {
            try pool.spawn(check_position, .{ &map, k.*, &count, &mutex });
        }
    }

    return count;
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
    const file = std.fs.cwd().openFile("../../../inputs/2024/day06/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(41, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day06/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(6, result);
}
