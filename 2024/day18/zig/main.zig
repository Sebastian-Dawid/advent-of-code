const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Vec2 = struct {
    x: u64,
    y: u64,
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

const Graph = struct {
    const Edge = struct { a: u64, b: u64 };
    allocator: Allocator,
    node_count: usize,
    adjacency_list: std.ArrayList(Edge),
    position_to_node: std.AutoArrayHashMap(Vec2, usize),
    incoming_bytes: []Vec2,
    bytes_corrupted: usize,

    fn init(comptime width: usize, comptime height: usize, file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.node_count = 0;
        self.bytes_corrupted = 0;

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();

        var incoming = std.ArrayList(Vec2).init(allocator);
        defer incoming.deinit();

        var buffer: [256]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            var split = std.mem.splitAny(u8, line, ",");
            const first = split.next() orelse return error.InvalidInput;
            const second = split.next() orelse return error.InvalidInput;
            try incoming.append(.{ .x = try std.fmt.parseInt(u64, first, 10), .y = try std.fmt.parseInt(u64, second, 10) });
        }

        self.incoming_bytes = try incoming.toOwnedSlice();
        self.adjacency_list = std.ArrayList(Edge).init(self.allocator);
        self.position_to_node = std.AutoArrayHashMap(Vec2, usize).init(self.allocator);

        var i: usize = 0;
        while (i < height) : (i += 1) {
            var j: usize = 0;
            while (j < width) : (j += 1) {
                try self.position_to_node.put(.{ .x = j, .y = i }, self.node_count);
                if (j > 0) {
                    if (self.position_to_node.get(.{ .x = j - 1, .y = i })) |left| {
                        try self.adjacency_list.append(.{ .a = left, .b = self.node_count });
                    }
                }
                if (i > 0) {
                    if (self.position_to_node.get(.{ .x = j, .y = i - 1 })) |above| {
                        try self.adjacency_list.append(.{ .a = above, .b = self.node_count });
                    }
                }
                self.node_count += 1;
            }
        }

        return self;
    }

    fn deinit(self: *@This()) void {
        self.allocator.free(self.incoming_bytes);
        self.adjacency_list.deinit();
        self.position_to_node.deinit();
    }

    fn simulate_incoming(self: *@This(), comptime count: usize) void {
        for (self.incoming_bytes[self.bytes_corrupted..], 0..) |p, i| {
            if (i >= count) break;
            const node = self.position_to_node.get(p) orelse continue;
            _ = self.position_to_node.swapRemove(p);

            var j: usize = 0;
            while (j < self.adjacency_list.items.len) {
                const e = self.adjacency_list.items[j];
                if (e.a == node or e.b == node) {
                    _ = self.adjacency_list.swapRemove(j);
                } else {
                    j += 1;
                }
            }
        }

        self.bytes_corrupted += count;
        self.node_count = self.position_to_node.count();
    }

    fn neighbors(self: *const @This(), node: u64) ![]u64 {
        var n = std.ArrayList(u64).init(self.allocator);
        defer n.deinit();
        for (self.adjacency_list.items) |e| {
            if (e.a == node) try n.append(e.b);
            if (e.b == node) try n.append(e.a);
        }
        return try n.toOwnedSlice();
    }

    fn bfs(self: *const @This(), allocator: Allocator) !std.AutoArrayHashMap(u64, u64) {
        var visited = std.AutoArrayHashMap(u64, u64).init(allocator);
        try visited.put(0, 0);

        var queue = std.ArrayList(struct { node: u64, distance: u64 }).init(allocator);
        defer queue.deinit();
        try queue.append(.{ .node = 0, .distance = 0 });

        while (queue.items.len > 0) {
            const v = queue.orderedRemove(0);

            const n = try self.neighbors(v.node);
            defer self.allocator.free(n);
            for (n) |_n| {
                for (visited.keys()) |k| {
                    if (_n == k) break;
                } else {
                    try queue.append(.{ .node = _n, .distance = v.distance + 1 });
                    try visited.put(_n, v.distance + 1);
                }
            }
        }

        return visited;
    }
};

fn part1(file: File, allocator: Allocator) !u64 {
    var graph = try Graph.init(71, 71, file, allocator);
    defer graph.deinit();

    graph.simulate_incoming(1024);

    var result = try graph.bfs(allocator);
    defer result.deinit();

    return result.get(graph.position_to_node.get(.{ .x = 70, .y = 70 }).?).?;
}

fn part2(file: File, allocator: Allocator) !Vec2 {
    var graph = try Graph.init(71, 71, file, allocator);
    defer graph.deinit();

    graph.simulate_incoming(1024);

    var result = try graph.bfs(allocator);
    defer result.deinit();

    var last_byte = graph.incoming_bytes[1023];
    while (result.get(graph.position_to_node.get(.{ .x = 70, .y = 70 }).?)) |_| {
        result.deinit();

        graph.simulate_incoming(1);
        result = try graph.bfs(allocator);
        last_byte = graph.incoming_bytes[graph.bytes_corrupted - 1];
    }

    return last_byte;
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
        std.debug.print("Part 1: {}\n", .{try part2(file, allocator)});
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day18/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;

    var graph = try Graph.init(7, 7, file, allocator);
    defer graph.deinit();

    graph.simulate_incoming(12);

    var result = try graph.bfs(allocator);
    defer result.deinit();

    try std.testing.expectEqual(22, result.get(graph.position_to_node.get(.{ .x = 6, .y = 6 }).?).?);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day18/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;

    var graph = try Graph.init(7, 7, file, allocator);
    defer graph.deinit();

    graph.simulate_incoming(12);

    var result = try graph.bfs(allocator);
    defer result.deinit();

    var last_byte = graph.incoming_bytes[graph.bytes_corrupted];
    while (result.get(graph.position_to_node.get(.{ .x = 6, .y = 6 }).?)) |_| {
        result.deinit();

        graph.simulate_incoming(1);
        result = try graph.bfs(allocator);
        last_byte = graph.incoming_bytes[graph.bytes_corrupted - 1];
    }

    try std.testing.expectEqual(Vec2{.x = 6, .y = 1}, last_byte);
}
