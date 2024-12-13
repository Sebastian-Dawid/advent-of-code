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
    fn sub(self: @This(), other: @This()) @This() {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }
    fn is_zero(self: @This()) bool {
        return self.x == 0 and self.y == 0;
    }
    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("({} {})", .{ self.x, self.y });
    }
};

const ClawMachine = struct {
    a_button: Vec2,
    b_button: Vec2,
    target: Vec2,

    fn init(definition: *std.mem.SplitIterator(u8, .any)) !@This() {
        var self: @This() = undefined;
        const parse_vector = struct {
            fn vector(data: *std.mem.SplitIterator(u8, .any)) !Vec2 {
                _ = data.next();
                var vec: Vec2 = undefined;
                if (data.next()) |line| {
                    vec.x = try std.fmt.parseInt(i64, line[3..], 10);
                } else {
                    return error.InsufficientNumberOfValues;
                }
                if (data.next()) |line| {
                    vec.y = try std.fmt.parseInt(i64, line[3..], 10);
                } else {
                    return error.InsufficientNumberOfValues;
                }
                return vec;
            }
        }.vector;
        if (definition.next()) |line| {
            var data = std.mem.splitAny(u8, line, ":,");
            self.a_button = try parse_vector(&data);
        } else return error.InsufficientNumberOfLines;
        if (definition.next()) |line| {
            var data = std.mem.splitAny(u8, line, ":,");
            self.b_button = try parse_vector(&data);
        } else return error.InsufficientNumberOfLines;
        if (definition.next()) |line| {
            var data = std.mem.splitAny(u8, line, ":,");
            self.target = try parse_vector(&data);
        } else return error.InsufficientNumberOfLines;
        return self;
    }

    fn find_optimal_inputs(self: *const @This(), comptime max_iterations: u64) ?u64 {
        var cost: u64 = std.math.maxInt(u64);
        var found = false;
        var i: u64 = 0;
        outer: while (i < max_iterations) : (i += 1) {
            var j: u64 = 0;
            while (j < max_iterations) : (j += 1) {
                if (self.target.sub(self.a_button.mul(@intCast(i))).sub(self.b_button.mul(@intCast(j))).is_zero()) {
                    if (cost > (i * 3 + j)) cost = i * 3 + j;
                    found = true;
                    continue :outer;
                }
            }
        }
        if (found) return cost;
        return null;
    }
};

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    const content = try reader.readAllAlloc(allocator, stat.size);
    defer allocator.free(content);

    var lines = std.mem.splitAny(u8, content, "\n");

    var machines = std.ArrayList(ClawMachine).init(allocator);
    defer machines.deinit();

    while (lines.peek()) |_| {
        try machines.append(try ClawMachine.init(&lines));
        _ = lines.next(); // discard empty line
    }

    var sum: u64 = 0;
    for (machines.items) |machine| {
        if (machine.find_optimal_inputs(100)) |cost| sum += cost;
    }

    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    _ = allocator; // autofix
    _ = file; // autofix
    return 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
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
    const file = std.fs.cwd().openFile("../../../inputs/2024/day13/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(480, result);
}
