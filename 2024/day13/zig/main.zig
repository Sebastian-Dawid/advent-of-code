const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = struct {
    x: f64,
    y: f64,
    fn mul(self: @This(), lambda: f64) @This() {
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
    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("({d: >7.2} {d: >7.2})", .{ self.x, self.y });
    }
};

const Mat2 = struct {
    a: f64,
    b: f64,
    c: f64,
    d: f64,
    fn det(self: @This()) f64 {
        return (self.a * self.d - self.b * self.c);
    }
    fn inverse(self: @This()) @This() {
        const d = self.det();
        return .{
            .a = self.d / d,
            .b = -self.b / d,
            .c = -self.c / d,
            .d = self.a / d,
        };
    }
    fn mul(self: @This(), other: Vec2) Vec2 {
        return .{
            .x = self.a * other.x + self.b * other.y,
            .y = self.c * other.x + self.d * other.y,
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
        try writer.print("|{d: >7.4} {d: >7.4}|\n|{d: >7.4} {d: >7.4}|", .{ self.a, self.b, self.c, self.d });
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
                    vec.x = try std.fmt.parseFloat(f64, line[3..]);
                } else {
                    return error.InsufficientNumberOfValues;
                }
                if (data.next()) |line| {
                    vec.y = try std.fmt.parseFloat(f64, line[3..]);
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

    fn find_optimal_inputs(self: *const @This()) ?u64 {
        const system = Mat2{ .a = self.a_button.x, .b = self.b_button.x, .c = self.a_button.y, .d = self.b_button.y };
        const inv = system.inverse();
        const solution_float = inv.mul(self.target);
        const solution = Vec2{ .x = @round(solution_float.x), .y = @round(solution_float.y) };

        const target = self.a_button.mul(solution.x).add(self.b_button.mul(solution.y));
        if (target.x != self.target.x or target.y != self.target.y) return null;

        return @as(u64, @intFromFloat(solution.x)) * 3 + @as(u64, @intFromFloat(solution.y));
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
        if (machine.find_optimal_inputs()) |cost| sum += cost;
    }

    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    const content = try reader.readAllAlloc(allocator, stat.size);
    defer allocator.free(content);

    var lines = std.mem.splitAny(u8, content, "\n");

    var machines = std.ArrayList(ClawMachine).init(allocator);
    defer machines.deinit();

    while (lines.peek()) |_| {
        var machine = try ClawMachine.init(&lines);
        machine.target = machine.target.add(.{ .x = 10000000000000, .y = 10000000000000 });
        try machines.append(machine);
        _ = lines.next(); // discard empty line
    }

    var sum: u64 = 0;
    for (machines.items) |machine| {
        if (machine.find_optimal_inputs()) |cost| sum += cost;
    }

    return sum;
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
