const std = @import("std");
const Allocator = std.mem.Allocator;

const MemoryMap = struct {
    allocator: Allocator,
    map: std.ArrayList(?u64),
    used_blocks: u64,
    free_blocks: u64,

    fn init(file: std.fs.File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.map = std.ArrayList(?u64).init(allocator);
        self.used_blocks = 0;
        self.free_blocks = 0;

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();
        const stat = try file.stat();

        const compressed = try reader.readAllAlloc(allocator, stat.size);
        defer allocator.free(compressed);

        var id: u64 = 0;
        for (compressed, 0..) |c, i| {
            if (c < 0x30 or c > 0x39) continue;
            const count: u64 = @as(u64, @intCast(c)) - 0x30;
            if (i % 2 == 0) {
                self.used_blocks += count;
                try self.map.appendNTimes(id, count);
                id += 1;
            } else {
                self.free_blocks += count;
                try self.map.appendNTimes(null, count);
            }
        }
        return self;
    }

    fn deinit(self: *@This()) void {
        self.map.deinit();
    }
};

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var memory_map = try MemoryMap.init(file, allocator);
    defer memory_map.deinit();

    var end: i64 = @intCast(memory_map.map.items.len - 1);
    var start: u64 = 0;
    while (end >= 0) : (end -= 1) {
        if (memory_map.map.items[@intCast(end)] != null) {
            while (start < memory_map.map.items.len and memory_map.map.items[start] != null) : (start += 1) {}
            if (start > end) break;
            std.mem.swap(?u64, &memory_map.map.items[@intCast(end)], &memory_map.map.items[start]);
        }
    }

    var checksum: u64 = 0;
    var i: u64 = 0;
    for (memory_map.map.items) |item| {
        if (item == null) break;
        checksum += item.? * i;
        i += 1;
    }

    return checksum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    var memory_map = try MemoryMap.init(file, allocator);
    defer memory_map.deinit();

    var end: i64 = @intCast(memory_map.map.items.len - 1);
    var start: u64 = 0;
    while (end >= 0) : (end -= 1) {
        if (memory_map.map.items[@intCast(end)] != null) {
            while (start < memory_map.map.items.len and memory_map.map.items[start] != null) : (start += 1) {}
            if (start > end) break;
            std.mem.swap(?u64, &memory_map.map.items[@intCast(end)], &memory_map.map.items[start]);
        }
    }

    var checksum: u64 = 0;
    var i: u64 = 0;
    for (memory_map.map.items) |item| {
        if (item == null) break;
        checksum += item.? * i;
        i += 1;
    }

    return checksum;
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
    const file = std.fs.cwd().openFile("../../../inputs/2024/day09/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(1928, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day09/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(2858, result);
}
