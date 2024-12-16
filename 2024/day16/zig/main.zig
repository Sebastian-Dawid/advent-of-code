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
    const Edge = struct { a: u64, b: u64, w: u64 };
    allocator: Allocator,
    node_count: usize,
    adjacency_list: []Edge,
    start: usize,
    end: struct { h: usize, v: usize },

    fn init(file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.node_count = 0;

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();
        const stat = try file.stat();

        var map = std.ArrayList(u8).init(allocator);
        defer map.deinit();

        var width: usize = 0;
        var height: usize = 0;

        while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', stat.size)) |line| {
            defer allocator.free(line);
            if (height == 0) width = line.len;
            try map.appendSlice(line);
            height += 1;
        }

        var position_to_nodes = std.AutoHashMap(Vec2, [2]u64).init(allocator);
        defer position_to_nodes.deinit();

        var i: usize = 0;
        while (i < height) : (i += 1) {
            var j: usize = 0;
            while (j < width) : (j += 1) {
                const index = i * width + j;
                switch (map.items[index]) {
                    '.', 'S', 'E' => {
                        var vertical: bool = false;
                        var horizontal: bool = false;
                        var count: usize = 0;
                        if (map.items[index + 1] == '.' or map.items[index + 1] == 'S' or map.items[index + 1] == 'E') {
                            count += 1;
                            horizontal = true;
                        }
                        if (map.items[index - 1] == '.' or map.items[index - 1] == 'S' or map.items[index - 1] == 'E') {
                            count += 1;
                            horizontal = true;
                        }
                        if (map.items[index + width] == '.' or map.items[index + width] == 'S' or map.items[index + width] == 'E') {
                            count += 1;
                            vertical = true;
                        }
                        if (map.items[index - width] == '.' or map.items[index - width] == 'S' or map.items[index - width] == 'E') {
                            count += 1;
                            vertical = true;
                        }
                        if (map.items[index] == 'S') self.start = self.node_count;
                        if (map.items[index] == 'E') self.end = .{ .h = self.node_count, .v = self.node_count + 1 };
                        if (count == 2 and !(vertical and horizontal) and map.items[index] != 'S' and map.items[index] != 'E') continue;
                        try position_to_nodes.put(Vec2{ .x = j, .y = i }, [2]u64{ self.node_count, self.node_count + 1 });
                        self.node_count += 2;
                    },
                    else => {},
                }
            }
        }

        var edges = std.ArrayList(Edge).init(allocator);
        defer edges.deinit();

        var it = position_to_nodes.keyIterator();
        while (it.next()) |k| {
            const node_a = position_to_nodes.get(k.*).?;
            first: {
                var x: usize = k.x + 1;
                while (position_to_nodes.get(Vec2{ .x = x, .y = k.y }) == null) : (x += 1) {
                    if (map.items[k.y * width + x] == '#') break :first;
                }
                const node_b = position_to_nodes.get(Vec2{ .x = x, .y = k.y }).?;
                try edges.append(.{ .a = node_a[0], .b = node_b[0], .w = x - k.x });
            }
            second: {
                var y: usize = k.y + 1;
                while (position_to_nodes.get(Vec2{ .x = k.x, .y = y }) == null) : (y += 1) {
                    if (map.items[y * width + k.x] == '#') break :second;
                }
                const node_b = position_to_nodes.get(Vec2{ .x = k.x, .y = y }).?;
                try edges.append(.{ .a = node_a[1], .b = node_b[1], .w = y - k.y });
            }
            try edges.append(.{ .a = node_a[0], .b = node_a[1], .w = 1000 });
        }

        self.adjacency_list = try edges.toOwnedSlice();

        return self;
    }
    fn deinit(self: *const @This()) void {
        self.allocator.free(self.adjacency_list);
    }

    fn neighbors(self: *const @This(), node: u64) ![]u64 {
        var n = std.ArrayList(u64).init(self.allocator);
        defer n.deinit();
        for (self.adjacency_list) |e| {
            if (e.a == node) try n.append(e.b);
            if (e.b == node) try n.append(e.a);
        }
        return try n.toOwnedSlice();
    }

    fn weight(self: *const @This(), a: u64, b: u64) !u64 {
        for (self.adjacency_list) |e| {
            if ((e.a == a and e.b == b) or (e.a == b and e.b == a)) return e.w;
        }
        return error.NoSuchEdge;
    }

    fn dijkstra(self: *const @This(), allocator: Allocator) !struct { pred: []?u64, pi: []u64 } {
        var pred = try allocator.alloc(?u64, self.node_count);
        var pi = try allocator.alloc(u64, self.node_count);
        var list = std.AutoHashMap(u64, u64).init(allocator);
        defer list.deinit();
        {
            var i: usize = 0;
            while (i < self.node_count) : (i += 1) {
                pred[i] = null;
                pi[i] = std.math.maxInt(u64);
            }
            pi[self.start] = 0;
            i = 0;
            while (i < self.node_count) : (i += 1) {
                try list.put(i, pi[i]);
            }
        }

        while (list.count() > 0) {
            var u: u64 = undefined;
            var min: u64 = std.math.maxInt(u64);
            var it = list.keyIterator();
            while (it.next()) |k| {
                if (list.get(k.*).? < min) {
                    u = k.*;
                    min = list.get(k.*).?;
                }
            }
            if (!list.remove(u)) continue;
            const n = try self.neighbors(u);
            defer self.allocator.free(n);
            for (n) |w| {
                if (pi[w] > pi[u] + try self.weight(u, w)) {
                    pi[w] = pi[u] + try self.weight(u, w);
                    pred[w] = u;
                    try list.put(w, pi[w]);
                }
            }
        }

        return .{ .pred = pred, .pi = pi };
    }
};

fn part1(file: File, allocator: Allocator) !u64 {
    const graph = try Graph.init(file, allocator);
    defer graph.deinit();

    const result = try graph.dijkstra(allocator);
    defer {
        allocator.free(result.pred);
        allocator.free(result.pi);
    }

    const ret = if (result.pi[graph.end.h] < result.pi[graph.end.v]) result.pi[graph.end.h] else result.pi[graph.end.v];
    return ret;
}

fn part2(file: File, allocator: Allocator) !u64 {
    const graph = try Graph.init(file, allocator);
    defer graph.deinit();

    const result = try graph.dijkstra(allocator);
    defer {
        allocator.free(result.pred);
        allocator.free(result.pi);
    }

    var tiles = std.AutoArrayHashMap(Graph.Edge, u1).init(allocator);
    defer tiles.deinit();
    var nodes = std.AutoHashMap(u64, u1).init(allocator);
    defer nodes.deinit();

    const end = if (result.pi[graph.end.h] < result.pi[graph.end.v]) graph.end.h else graph.end.v;
    var stack = std.ArrayList(u64).init(allocator);
    defer stack.deinit();
    try stack.append(end);

    while (stack.items.len > 0) {
        const e = stack.pop();
        try nodes.put(e - (e % 2), 1);
        const n = try graph.neighbors(e);
        defer graph.allocator.free(n);
        for (n) |w| {
            const weight = try graph.weight(e, w);
            if (result.pi[e] == result.pi[w] + weight) {
                try stack.append(w);
                if (weight != 1000) {
                    try tiles.put(Graph.Edge{ .a = e, .b = w, .w = weight - 1 }, 1);
                }
            }
        }
    }

    var sum: u64 = 0;
    for (tiles.keys()) |k| {
        sum += k.w;
    }
    return sum + nodes.count();
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

test "part 1.1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day16/test_1.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(7_036, result);
}

test "part 1.2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day16/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(11_048, result);
}

test "part 2.1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day16/test_1.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(45, result);
}

test "part 2.2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day16/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(64, result);
}
