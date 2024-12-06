const std = @import("std");
const Allocator = std.mem.Allocator;

const Map = struct {
    const Position = struct { x: u64, y: u64 };
    allocator: Allocator,
    obstacles: std.ArrayList(Position),
    width: u64,
    height: u64,

    fn init(allocator: Allocator) @This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.obstacles = std.ArrayList(Position).init(allocator);
        self.width = 0;
        self.height = 0;
    }
    fn deinit(self: @This()) void {
        self.obstacles.deinit();
    }
};

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();

    const stat = try file.stat();

    var map = std.ArrayList(u8).init(allocator);
    defer map.deinit();

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        try map.appendSlice(line);
    }
    std.debug.print("{any}\n", .{ map.items });

    return 0;
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
