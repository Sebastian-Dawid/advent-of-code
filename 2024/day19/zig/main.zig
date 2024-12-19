const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Trie = struct {
    const Color = enum(usize) {
        WHITE = 0,
        BLUE,
        BLACK,
        RED,
        GREEN,
        fn fromChar(c: u8) !@This() {
            return switch (c) {
                'w' => .WHITE,
                'u' => .BLUE,
                'b' => .BLACK,
                'r' => .RED,
                'g' => .GREEN,
                else => return error.InvalidCharacter,
            };
        }
    };
    const Node = struct {
        children: [5]?usize = [_]?usize{null} ** 5,
        sentinel: bool = false,
    };
    allocator: Allocator,
    nodes: std.ArrayList(Node),

    fn init(availables: [][]u8, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.nodes = std.ArrayList(Node).init(self.allocator);
        try self.nodes.append(.{});

        for (availables) |av| {
            var i: usize = 0;
            for (av) |a| {
                if (self.nodes.items[i].children[@intFromEnum(try Color.fromChar(a))]) |_i| {
                    i = _i;
                } else {
                    self.nodes.items[i].children[@intFromEnum(try Color.fromChar(a))] = self.nodes.items.len;
                    i = self.nodes.items.len;
                    try self.nodes.append(.{});
                }
            }
            self.nodes.items[i].sentinel = true;
        }

        return self;
    }

    fn deinit(self: *@This()) void {
        self.nodes.deinit();
    }

    fn find(self: *const @This(), pattern: []u8) !usize {
        var ways = try self.allocator.alloc(usize, pattern.len + 1);
        defer self.allocator.free(ways);
        for (ways, 0..) |_, i| ways[i] = 0;
        ways[0] = 1;

        var start: usize = 0;
        while (start < pattern.len) : (start += 1) {
            if (ways[start] > 0) {
                var i: usize = 0;
                var end: usize = start;
                while (end < pattern.len) : (end += 1) {
                    if (self.nodes.items[i].children[@intFromEnum(try Color.fromChar(pattern[end]))]) |_i| {
                        i = _i;
                        ways[end + 1] += if (self.nodes.items[i].sentinel) ways[start] else 0;
                    } else {
                        break;
                    }
                }
            }
        }
        return ways[pattern.len];
    }
};

fn part1(file: File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    const av = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size);
    if (av == null) return error.InvalidFormat;
    defer allocator.free(av.?);
    var split = std.mem.splitAny(u8, av.?, ", ");
    var count: usize = 0;
    while (split.next()) |s| {
        if (s.len == 0) continue;
        count += 1;
    }
    split.reset();
    var availables = try allocator.alloc([]u8, count);
    defer {
        for (availables) |a| allocator.free(a);
        allocator.free(availables);
    }

    var i: usize = 0;
    while (split.next()) |s| {
        if (s.len == 0) continue;
        availables[i] = try allocator.alloc(u8, s.len);
        @memcpy(availables[i], s);
        i += 1;
    }

    var trie = try Trie.init(availables, allocator);
    defer trie.deinit();

    try reader.skipUntilDelimiterOrEof('\n');
    count = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        if (try trie.find(line) > 0) count += 1;
    }

    return count;
}

fn part2(file: File, allocator: Allocator) !u64 {
    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    const stat = try file.stat();

    const av = try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size);
    if (av == null) return error.InvalidFormat;
    defer allocator.free(av.?);
    var split = std.mem.splitAny(u8, av.?, ", ");
    var count: usize = 0;
    while (split.next()) |s| {
        if (s.len == 0) continue;
        count += 1;
    }
    split.reset();
    var availables = try allocator.alloc([]u8, count);
    defer {
        for (availables) |a| allocator.free(a);
        allocator.free(availables);
    }

    var i: usize = 0;
    while (split.next()) |s| {
        if (s.len == 0) continue;
        availables[i] = try allocator.alloc(u8, s.len);
        @memcpy(availables[i], s);
        i += 1;
    }

    var trie = try Trie.init(availables, allocator);
    defer trie.deinit();

    try reader.skipUntilDelimiterOrEof('\n');
    count = 0;
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
        defer allocator.free(line);
        count += try trie.find(line);
    }

    return count;
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
    const file = std.fs.cwd().openFile("../../../inputs/2024/day19/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(6, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day19/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(16, result);
}
