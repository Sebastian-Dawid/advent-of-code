const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = struct {
    x: i64,
    y: i64,
    fn mul(self: @This(), lambda: i64) @This() {
        return .{
            .x = self.x * lambda,
            .y = self.y * lambda,
        };
    }
    fn add(self: @This(), other: @This()) @This() {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }
    fn mod(self: @This(), other: @This()) @This() {
        return .{
            .x = @mod(self.x, other.x),
            .y = @mod(self.y, other.y),
        };
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

const Robot = struct {
    position: Vec2,
    velocity: Vec2,
    fn init(ci: []const u8) !@This() {
        var self: Robot = undefined;
        var split = std.mem.splitAny(u8, ci, "=, ");
        _ = split.next();
        if (split.next()) |v| {
            self.position.x = try std.fmt.parseInt(i64, v, 10);
        } else {
            return error.InsufficientNumberOfValues;
        }
        if (split.next()) |v| {
            self.position.y = try std.fmt.parseInt(i64, v, 10);
        } else {
            return error.InsufficientNumberOfValues;
        }
        _ = split.next();
        if (split.next()) |v| {
            self.velocity.x = try std.fmt.parseInt(i64, v, 10);
        } else {
            return error.InsufficientNumberOfValues;
        }
        if (split.next()) |v| {
            self.velocity.y = try std.fmt.parseInt(i64, v, 10);
        } else {
            return error.InsufficientNumberOfValues;
        }
        return self;
    }
    fn peek(self: *const @This(), time: i64) Vec2 {
        return self.position.add(self.velocity.mul(time));
    }
    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("[ p = {}, v = {} ]", .{ self.position, self.velocity });
    }
};

fn part1(file: std.fs.File, allocator: Allocator, width: u64, height: u64) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        try robots.append(try Robot.init(line));
    }

    var quadrants = [4]u64{0, 0, 0, 0};
    const center = Vec2{ .x = @intCast(width/2), .y = @intCast(height/2) };
    for (robots.items) |robot| {
        const pos = robot.peek(100).mod(Vec2{ .x = @intCast(width), .y = @intCast(height) });
        if (pos.x < center.x and pos.y < center.y) {
            quadrants[0] += 1;
        } else if (pos.x < center.x and pos.y > center.y) {
            quadrants[1] += 1;
        } else if (pos.x > center.x and pos.y < center.y) {
            quadrants[2] += 1;
        } else if (pos.x > center.x and pos.y > center.y) {
            quadrants[3] += 1;
        }
    }
    return quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3];
}

fn part2(file: std.fs.File, allocator: Allocator, width: u64, height: u64) !void {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        try robots.append(try Robot.init(line));
    }

    //const center = Vec2{ .x = @intCast(width/2), .y = @intCast(height/2) };
    var count: u64 = 0;
    outer: while (count < 10_403) : (count += 1) {
        var list = std.AutoHashMap(Vec2, u64).init(allocator);
        defer list.deinit();

        for (robots.items) |robot| {
            const pos = robot.peek(@intCast(count)).mod(Vec2{ .x = @intCast(width), .y = @intCast(height) });
            const v = try list.getOrPutValue(pos, 0);
            v.value_ptr.* += 1;
            if (v.value_ptr.* >= 2) continue :outer;
        }

        std.debug.print("=== Iteration: {}\n", .{count});
        var i: i64 = 0;
        while (i < @as(i64, @intCast(height))) : (i += 1) {
            var j: i64 = 0;
            inner: while (j < @as(i64, @intCast(width))) : (j += 1) {
                var it = list.keyIterator();
                while (it.next()) |pos| {
                    if (pos.x == j and pos.y == i) {
                        std.debug.print("#", .{});
                        continue :inner;
                    }
                } else std.debug.print(".", .{});
            }
            std.debug.print("\n", .{});
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next();
    const filename = args.next() orelse return error.NoFileGiven;
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FailedToOpenFile;
        defer file.close();
        std.debug.print("Part 1: {}\n", .{ try part1(file, allocator, 101, 103) });
    }
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FailedToOpenFile;
        defer file.close();
        std.debug.print("Part 2:\n", .{});
        try part2(file, allocator, 101, 103);
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day14/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator, 11, 7);
    try std.testing.expectEqual(12, result);
}
