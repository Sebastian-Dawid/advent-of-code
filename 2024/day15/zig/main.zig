const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Solver = struct {
    const Direction = enum { UP, RIGHT, DOWN, LEFT };
    const Object = enum { WALL, BOX };
    const TileWidth = enum(u64) { ONE = 1, TWO = 2 };
    const Vec2 = struct {
        x: u64,
        y: u64,
        fn move(self: *@This(), direction: Direction) void {
            switch (direction) {
                Direction.UP => self.y -= 1,
                Direction.RIGHT => self.x += 1,
                Direction.DOWN => self.y += 1,
                Direction.LEFT => self.x -= 1,
            }
        }
        fn peek(self: *const @This(), direction: Direction) Vec2 {
            switch (direction) {
                Direction.UP => return .{ .x = self.x, .y = self.y - 1 },
                Direction.RIGHT => return .{ .x = self.x + 1, .y = self.y },
                Direction.DOWN => return .{ .x = self.x, .y = self.y + 1 },
                Direction.LEFT => return .{ .x = self.x - 1, .y = self.y },
            }
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
    robot: Vec2,
    map: std.AutoHashMap(Vec2, Object),
    instructions: []Direction,
    current_instruction: usize,
    tile_width: TileWidth,

    fn init(comptime tile_width: TileWidth, file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.map = std.AutoHashMap(Vec2, Object).init(allocator);
        self.tile_width = tile_width;

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();
        const stat = try file.stat();

        var y: u64 = 0;
        while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
            defer allocator.free(line);
            if (line.len == 0) break;
            for (line, 0..) |c, x| {
                switch (c) {
                    '#' => try self.map.put(.{ .x = x * @intFromEnum(tile_width), .y = y }, .WALL),
                    'O' => try self.map.put(.{ .x = x * @intFromEnum(tile_width), .y = y }, .BOX),
                    '@' => self.robot = .{ .x = x * @intFromEnum(tile_width), .y = y },
                    else => {},
                }
            }
            y += 1;
        }

        var instructions = std.ArrayList(Direction).init(allocator);
        defer instructions.deinit();

        while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
            defer allocator.free(line);
            for (line) |i| {
                switch (i) {
                    '^' => try instructions.append(.UP),
                    '>' => try instructions.append(.RIGHT),
                    'v' => try instructions.append(.DOWN),
                    '<' => try instructions.append(.LEFT),
                    else => {},
                }
            }
        }

        self.instructions = try instructions.toOwnedSlice();
        self.current_instruction = 0;
        return self;
    }

    fn deinit(self: *@This()) void {
        self.map.deinit();
        self.allocator.free(self.instructions);
    }

    fn check_position(self: *const @This(), position: Vec2, instruction: Direction) ?Object {
        if (self.tile_width == .ONE) return self.map.get(position);

        switch (instruction) {
            .RIGHT => return self.map.get(position),
            else => {
                if (self.map.get(position)) |v| return v;
                return self.map.get(position.peek(.LEFT));
            },
        }
    }

    fn check_for_wall(self: *const @This(), _position: Vec2, instruction: Direction) bool {
        var position = _position;
        const check = self.check_position(position, instruction);
        switch (self.tile_width) {
            .ONE => {
                if (check == null) return true;
                if (check.? == .WALL) return false;
                return self.check_for_wall(position.peek(instruction), instruction);
            },
            .TWO => {
                if (self.map.get(position) == null) position.move(.LEFT);
                if (check == null) return true;
                if (check.? == .WALL) return false;
                switch (instruction) {
                    .RIGHT => {
                        return self.check_for_wall(position.peek(instruction).peek(instruction), instruction);
                    },
                    .LEFT => {
                        return self.check_for_wall(position.peek(instruction), instruction);
                    },
                    .UP, .DOWN => {
                        return (self.check_for_wall(position.peek(instruction), instruction) and self.check_for_wall(position.peek(.RIGHT).peek(instruction), instruction));
                    },
                }
            },
        }
    }

    fn move(self: *@This(), _position: Vec2, instruction: Direction) !void {
        var position = _position;
        switch (self.tile_width) {
            .ONE => {
                if (self.map.get(position) == null) return;
                try self.move(position.peek(instruction), instruction);
            },
            .TWO => {
                if (self.check_position(position, instruction) == null) return;
                if (self.map.get(position) == null) position.move(.LEFT);

                switch (instruction) {
                    .RIGHT => {
                        try self.move(position.peek(instruction).peek(instruction), instruction);
                    },
                    .LEFT => {
                        try self.move(position.peek(instruction), instruction);
                    },
                    .UP, .DOWN => {
                        try self.move(position.peek(instruction), instruction);
                        try self.move(position.peek(.RIGHT).peek(instruction), instruction);
                    },
                }
            },
        }
        _ = self.map.remove(position);
        try self.map.put(position.peek(instruction), .BOX);
    }

    fn step(self: *@This()) !bool {
        if (self.current_instruction >= self.instructions.len) return false;
        const instruction = self.instructions[self.current_instruction];

        if (self.check_for_wall(self.robot.peek(instruction), instruction)) {
            try self.move(self.robot.peek(instruction), instruction);
            self.robot.move(instruction);
        }

        self.current_instruction += 1;
        return true;
    }
};

fn part1(file: File, allocator: Allocator) !u64 {
    var solver = try Solver.init(.ONE, file, allocator);
    defer solver.deinit();

    while (try solver.step()) {}

    var sum: u64 = 0;
    var it = solver.map.keyIterator();
    while (it.next()) |k| {
        if (solver.map.get(k.*)) |v| {
            if (v == .BOX) sum += 100 * k.y + k.x;
        }
    }

    return sum;
}

fn part2(file: File, allocator: Allocator) !u64 {
    var solver = try Solver.init(.TWO, file, allocator);
    defer solver.deinit();

    while (try solver.step()) {}

    var sum: u64 = 0;
    var it = solver.map.keyIterator();
    while (it.next()) |k| {
        if (solver.map.get(k.*)) |v| {
            if (v == .BOX) {
                sum += 100 * k.y + k.x;
            }
        }
    }
    return sum;
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
        std.debug.print("Part 1: {}\n", .{try part1(file, allocator)});
    }
    {
        const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch return error.FailedToOpenFile;
        defer file.close();
        std.debug.print("Part 2: {}\n", .{try part2(file, allocator)});
    }
}

test "part 1.1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day15/test_1.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(2028, result);
}

test "part 1.2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day15/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(10_092, result);
}

test "part 2.1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day15/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(9_021, result);
}

test "part 2.2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day15/test_3.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(618, result);
}
