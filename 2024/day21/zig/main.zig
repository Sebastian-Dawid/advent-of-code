const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Vec2 = struct {
    x: i64,
    y: i64,

    fn sub(self: @This(), other: @This()) @This() {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
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

fn Solver(comptime max_robots: usize) type {
    return struct {
        const NumPad = enum(usize) {
            A = 0,
            @"0" = 1,
            @"1" = 2,
            @"2" = 3,
            @"3" = 4,
            @"4" = 5,
            @"5" = 6,
            @"6" = 7,
            @"7" = 8,
            @"8" = 9,
            @"9" = 10,
            fn fromChar(char: u8) @This() {
                return switch (char) {
                    'A' => NumPad.A,
                    '0' => NumPad.@"0",
                    '1' => NumPad.@"1",
                    '2' => NumPad.@"2",
                    '3' => NumPad.@"3",
                    '4' => NumPad.@"4",
                    '5' => NumPad.@"5",
                    '6' => NumPad.@"6",
                    '7' => NumPad.@"7",
                    '8' => NumPad.@"8",
                    '9' => NumPad.@"9",
                    else => std.debug.panic("Invalid Character: {c}\n", .{char}),
                };
            }
        };
        const NumPadMap = [_]Vec2{
            .{ .x = 2, .y = 0 },
            .{ .x = 1, .y = 0 },
            .{ .x = 0, .y = 1 },
            .{ .x = 1, .y = 1 },
            .{ .x = 2, .y = 1 },
            .{ .x = 0, .y = 2 },
            .{ .x = 1, .y = 2 },
            .{ .x = 2, .y = 2 },
            .{ .x = 0, .y = 3 },
            .{ .x = 1, .y = 3 },
            .{ .x = 2, .y = 3 },
        };

        const DirPad = enum(usize) {
            A = 0,
            @"^" = 1,
            @"<" = 2,
            v = 3,
            @">" = 4,
            fn fromChar(char: u8) @This() {
                return switch (char) {
                    'A' => DirPad.A,
                    '^' => DirPad.@"^",
                    '<' => DirPad.@"<",
                    'v' => DirPad.v,
                    '>' => DirPad.@">",
                    else => std.debug.panic("Invalid Character: {c}\n", .{char}),
                };
            }
        };
        const DirPadMap = [_]Vec2{
            .{ .x = 2, .y = 1 },
            .{ .x = 1, .y = 1 },
            .{ .x = 0, .y = 0 },
            .{ .x = 1, .y = 0 },
            .{ .x = 2, .y = 0 },
        };
        allocator: Allocator,
        input: std.ArrayList([]u8),
        cache: std.StringHashMap([max_robots]usize),

        fn init(file: File, allocator: Allocator) !@This() {
            var self: @This() = undefined;
            self.allocator = allocator;
            self.input = std.ArrayList([]u8).init(self.allocator);
            self.cache = std.StringHashMap([max_robots]usize).init(self.allocator);

            var buffered_reader = std.io.bufferedReader(file.reader());
            const reader = buffered_reader.reader();
            const stat = try file.stat();

            while (try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', stat.size)) |line| {
                try self.input.append(line);
            }

            return self;
        }
        fn resetCache(self: *@This()) void {
            var it = self.cache.keyIterator();
            while (it.next()) |k| self.allocator.free(k.*);
            self.cache.deinit();
            self.cache = std.StringHashMap([max_robots]usize).init(self.allocator);
        }
        fn deinit(self: *@This()) void {
            for (self.input.items) |s| self.allocator.free(s);
            self.input.deinit();
            var it = self.cache.keyIterator();
            while (it.next()) |k| self.allocator.free(k.*);
            self.cache.deinit();
        }

        fn getNumPadSequences(self: *const @This(), input: usize, allocator: Allocator) ![]u8 {
            var sequence = std.ArrayList(u8).init(allocator);
            defer sequence.deinit();

            var current = NumPadMap[@intFromEnum(NumPad.A)];

            for (self.input.items[input]) |c| {
                const destination = NumPadMap[@intFromEnum(NumPad.fromChar(c))];
                const d = destination.sub(current);

                var horizontal = std.ArrayList(u8).init(self.allocator);
                defer horizontal.deinit();
                var vertical = std.ArrayList(u8).init(self.allocator);
                defer vertical.deinit();

                var i: usize = 0;
                while (i < @as(usize, @intCast(@abs(d.x)))) : (i += 1) {
                    if (d.x >= 0) {
                        try horizontal.append('>');
                    } else {
                        try horizontal.append('<');
                    }
                }
                i = 0;
                while (i < @as(usize, @intCast(@abs(d.y)))) : (i += 1) {
                    if (d.y >= 0) {
                        try vertical.append('^');
                    } else {
                        try vertical.append('v');
                    }
                }

                if (current.y == 0 and destination.x == 0) {
                    try sequence.appendSlice(vertical.items);
                    try sequence.appendSlice(horizontal.items);
                } else if (current.x == 0 and destination.y == 0) {
                    try sequence.appendSlice(horizontal.items);
                    try sequence.appendSlice(vertical.items);
                } else if (d.x < 0) {
                    try sequence.appendSlice(horizontal.items);
                    try sequence.appendSlice(vertical.items);
                } else {
                    try sequence.appendSlice(vertical.items);
                    try sequence.appendSlice(horizontal.items);
                }

                current = destination;
                try sequence.append('A');
            }

            return try sequence.toOwnedSlice();
        }

        fn getDirPadSequences(self: *const @This(), input: []u8, allocator: Allocator) ![]u8 {
            var sequence = std.ArrayList(u8).init(allocator);
            defer sequence.deinit();

            var current = DirPadMap[@intFromEnum(DirPad.A)];

            for (input) |c| {
                const destination = DirPadMap[@intFromEnum(DirPad.fromChar(c))];
                const d = destination.sub(current);

                var horizontal = std.ArrayList(u8).init(self.allocator);
                defer horizontal.deinit();
                var vertical = std.ArrayList(u8).init(self.allocator);
                defer vertical.deinit();

                var i: usize = 0;
                while (i < @as(usize, @intCast(@abs(d.x)))) : (i += 1) {
                    if (d.x >= 0) {
                        try horizontal.append('>');
                    } else {
                        try horizontal.append('<');
                    }
                }
                i = 0;
                while (i < @as(usize, @intCast(@abs(d.y)))) : (i += 1) {
                    if (d.y >= 0) {
                        try vertical.append('^');
                    } else {
                        try vertical.append('v');
                    }
                }

                if (current.x == 0 and destination.y == 1) {
                    try sequence.appendSlice(horizontal.items);
                    try sequence.appendSlice(vertical.items);
                } else if (current.y == 1 and destination.x == 0) {
                    try sequence.appendSlice(vertical.items);
                    try sequence.appendSlice(horizontal.items);
                } else if (d.x < 0) {
                    try sequence.appendSlice(horizontal.items);
                    try sequence.appendSlice(vertical.items);
                } else {
                    try sequence.appendSlice(vertical.items);
                    try sequence.appendSlice(horizontal.items);
                }

                current = destination;
                try sequence.append('A');
            }

            return try sequence.toOwnedSlice();
        }

        fn countSequences(self: *@This(), input: []u8, robot: usize) !usize {
            const key = try self.allocator.dupe(u8, input);
            const key_not_present = self.cache.get(key) == null;
            defer {
                if (!key_not_present) self.allocator.free(key);
            }

            if (self.cache.get(key)) |value| {
                if (robot <= value.len and value[robot - 1] != 0) 
                {
                    return value[robot - 1];
                }
            }

            if (key_not_present) {
                try self.cache.put(key, [_]usize{ 0 } ** max_robots);
            }

            const sequence = try self.getDirPadSequences(input, self.allocator);
            defer self.allocator.free(sequence);
            if (robot == max_robots) return sequence.len;

            var count: usize = 0;
            var last: usize = 0;
            for (sequence, 0..) |c, i| {
                if (c == 'A') {
                    const v = try self.countSequences(sequence[last..(i+1)], robot+1);
                    count += v;
                    last = i+1;
                }
            }

            if (self.cache.getPtr(key)) |k| {
                k.*[robot-1] = count;
            }
            return count;
        }
    };
}

fn part(comptime count: usize, file: File, allocator: Allocator) !u64 {
    var solver = try Solver(count).init(file, allocator);
    defer solver.deinit();

    var sum: usize = 0;
    for (solver.input.items, 0..) |line, i| {
        const moves = try solver.getNumPadSequences(i, allocator);
        defer allocator.free(moves);
        const length = try solver.countSequences(moves, 1);
        const num = try std.fmt.parseInt(usize, line[0..line.len-1], 10);
        sum += num * length;
        solver.resetCache();
    }

    return sum;
}

fn part1(file: File, allocator: Allocator) !u64 {
    return try part(2, file, allocator);
}

fn part2(file: File, allocator: Allocator) !u64 {
    return try part(25, file, allocator);
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
    {
        const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer file.close();
        std.debug.print("Part 2: {}\n", .{try part2(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day21/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(126384, result);
}
