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
    map: std.AutoArrayHashMap(Vec2, Tile),
    start: Vec2,
    end: Vec2,
    width: usize,
    height: usize,

    fn init(file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.map = std.AutoArrayHashMap(Vec2, Tile).init(self.allocator);

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();
        const stat = try file.stat();

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
                        try self.map.put(p, .{ .variant = .PATH, .index = null });
                    },
                    '#' => {
                        try self.map.put(p, .{ .variant = .WALL, .index = null });
                    },
                    else => {},
                }
            }
            height += 1;
        }
        self.width = width;
        self.height = height;

        var length: usize = 0;
        var current = self.start;
        while (current.x == self.end.x and current.y == self.end.y) : (length += 1) {
            try self.map.put(current, .{ .variant = .PATH, .index = length });
            for (Direction.ALL) |dir| {
                if (self.map.get(current.add(Vec2.fromDirection(dir)))) |next| {
                    if (next.variant == .PATH and next.index == null) {
                        current = current.add(Vec2.fromDirection(dir));
                        break;
                    }
                }
            }
        }

        return self;
    }

    fn deinit(self: *@This()) void {
        self.map.deinit();
    }
};

fn part1(file: File, allocator: Allocator) !u64 {
    var solver = try Solver.init(file, allocator);
    defer solver.deinit();
    return 0;
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
        std.debug.print("Part 1: {}\n", .{try part1(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day20/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(0, result);
}
