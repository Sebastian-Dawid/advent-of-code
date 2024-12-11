const std = @import("std");
const Allocator = std.mem.Allocator;

const Solver = struct {
    const ValuePair = struct { value: u64, depth: u64 };
    allocator: Allocator,
    rocks: std.AutoHashMap(ValuePair, u64),

    fn init(allocator: Allocator) @This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.rocks = @TypeOf(self.rocks).init(allocator);
        return self;
    }

    fn deinit(self: *@This()) void {
        self.rocks.deinit();
    }

    fn blinks(self: *@This(), value: u64, depth: u64) !u64 {
        if (depth == 0) return 1;

        if (self.rocks.get(.{ .value = value, .depth = depth })) |v| {
            return v;
        }

        var count: u64 = undefined;
        if (value == 0) {
            count = try self.blinks(1, depth - 1);
        } else if ((std.math.log10_int(value) + 1) % 2 == 0) {
            const div = try std.math.powi(u64, 10, (std.math.log10_int(value)+1)/2);
            count = try self.blinks(value / div, depth - 1) + try self.blinks(value % div, depth - 1);
        } else {
            count = try self.blinks(value * 2024, depth - 1);
        }
        
        try self.rocks.put(.{ .value = value, .depth = depth }, count);

        return count;
    }
};

fn solve(comptime count: u64, file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    const input = (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) orelse return error.EmptyFile;
    defer allocator.free(input);

    var solver: Solver = Solver.init(allocator);
    defer solver.deinit();

    var split = std.mem.splitAny(u8, input, " ");
    var sum: u64 = 0;
    while (split.next()) |num| {
        const number = try std.fmt.parseInt(u64, num, 10);
        sum += try solver.blinks(number, count);
    }

    return sum;
}

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    return solve(25, file, allocator);
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    return solve(75, file, allocator);
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
    const file = std.fs.cwd().openFile("../../../inputs/2024/day11/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(55312, result);
}
