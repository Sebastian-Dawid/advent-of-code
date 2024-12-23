const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Graph = struct {
    const Edge = struct {
        a: usize,
        b: usize,

        fn eql(self: @This(), other: @This()) bool {
            return self.a == other.a and self.b == other.b or self.a == other.b and self.b == other.a;
        }

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try writer.print("({})<->({})", .{ self.a, self.b });
        }
    };

    allocator: Allocator,
    nodes: std.ArrayList([2]u8),
    edges: std.ArrayList(Edge),

    fn init(file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.nodes = std.ArrayList([2]u8).init(self.allocator);
        self.edges = std.ArrayList(Edge).init(self.allocator);

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();

        var buffer: [6]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            var split = std.mem.splitAny(u8, line, "-");
            const first = if (split.next()) |n| [_]u8{ n[0], n[1] } else continue;
            const second = if (split.next()) |n| [_]u8{ n[0], n[1] } else continue;

            var index: [2]usize = undefined;
            for ([_][2]u8{ first, second }, 0..) |elem, i| {
                for (self.nodes.items, 0..) |node, j| {
                    if (std.mem.eql(u8, &node, &elem)) {
                        index[i] = j;
                        break;
                    }
                } else {
                    index[i] = self.nodes.items.len;
                    try self.nodes.append(elem);
                }
            }

            var new_edge = Edge{ .a = index[0], .b = index[1] };
            for (self.edges.items) |edge| {
                if (new_edge.eql(edge)) break;
            } else {
                try self.edges.append(new_edge);
            }
        }

        return self;
    }

    fn deinit(self: *@This()) void {
        self.nodes.deinit();
        self.edges.deinit();
    }

    fn neighbors(self: *const @This(), node: usize) ![]usize {
        var n = std.ArrayList(usize).init(self.allocator);
        defer n.deinit();
        for (self.edges.items) |e| {
            if (e.a == node) try n.append(e.b);
            if (e.b == node) try n.append(e.a);
        }
        return try n.toOwnedSlice();
    }

    const Triangle = struct {
        vertices: [3]usize,
        fn eql(self: @This(), other: @This()) bool {
            var count: usize = 0;
            inline for (self.vertices) |v1| {
                inline for (other.vertices) |v2| {
                    if (v1 == v2) {
                        count += 1;
                        break;
                    }
                }
            }
            return count == 3;
        }
    };
    fn find_triangles(self: *const @This()) ![]Triangle {
        var triangles = std.ArrayList(Triangle).init(self.allocator);
        defer triangles.deinit();

        for (self.edges.items) |edge| {
            const na = try self.neighbors(edge.a);
            defer self.allocator.free(na);
            const nb = try self.neighbors(edge.b);
            defer self.allocator.free(nb);

            for (na) |a| {
                for (nb) |b| {
                    if (a == b) {
                        const tri = Triangle{ .vertices = [_]usize{ edge.a, edge.b, a } };
                        for (triangles.items) |t| {
                            if (t.eql(tri)) break;
                        } else {
                            try triangles.append(tri);
                        }
                    }
                }
            }
        }

        return try triangles.toOwnedSlice();
    }

    const Set = struct {
        allocator: Allocator,
        items: std.AutoHashMap(usize, void),

        fn init(allocator: Allocator) @This() {
            var self: @This() = undefined;
            self.allocator = allocator;
            self.items = std.AutoHashMap(usize, void).init(self.allocator);
            return self;
        }

        fn deinit(self: *@This()) void {
            self.items.deinit();
        }

        fn empty(self: *const @This()) bool {
            return self.items.count() == 0;
        }

        fn copy(self: *const @This()) !@This() {
            return .{ .allocator = self.allocator, .items = try self.items.clone() };
        }

        fn add(self: *@This(), item: usize) !void {
            try self.items.put(item, void{});
        }

        fn addCopy(self: *const @This(), item: usize) !@This() {
            var c = try self.copy();
            try c.add(item);
            return c;
        }

        fn intersect(self: *@This(), items: []usize) void {
            var it = self.items.keyIterator();
            while (it.next()) |v| {
                for (items) |n| {
                    if (v.* == n) break;
                } else {
                    _ = self.items.remove(v.*);
                }
            }
        }

        fn intersectCopy(self: *const @This(), items: []usize) !@This() {
            var c = try self.copy();
            c.intersect(items);
            return c;
        }

        fn remove(self: *@This(), item: usize) void {
            _ = self.items.remove(item);
        }

        fn removeCopy(self: *const @This(), item: usize) !@This() {
            var c = try self.copy();
            c.remove(item);
            return c;
        }

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            var it = self.items.keyIterator();
            try writer.print("{{ ", .{});
            while (it.next()) |k| {
                try writer.print("{},", .{k.*});
            }
            try writer.print(" }},", .{});
        }
    };

    fn choosePivot(self: *const @This(), vertices: Set) usize {
        var max: usize = 0;
        var pivot: usize = 0;
        var it = vertices.items.keyIterator();
        while (it.next()) |k| {
            const n = self.neighbors(k.*) catch continue;
            defer self.allocator.free(n);
            if (n.len > max) {
                max = n.len;
                pivot = k.*;
            }
        }
        return pivot;
    }

    fn bronKerboschImpl(
        self: *const @This(),
        _R: Set,
        _P: Set,
        _X: Set,
        cliques: *std.ArrayList(Set),
    ) !bool {
        if (_P.empty() and _X.empty()) {
            try cliques.append(_R);
            return false;
        }

        var R = try _R.copy();
        defer R.deinit();
        var P = try _P.copy();
        defer P.deinit();
        var X = try _X.copy();
        defer X.deinit();

        var combined = try P.copy();
        defer combined.deinit();
        var i = X.items.keyIterator();
        while (i.next()) |v| {
            try combined.add(v.*);
        }

        const Nu = try self.neighbors(self.choosePivot(combined));
        defer self.allocator.free(Nu);

        var P_copy = try P.copy();
        defer P_copy.deinit();

        for (Nu) |n| P_copy.remove(n);

        var it = P_copy.items.keyIterator();
        while (it.next()) |_v| {
            const v = _v.*;
            var __R = try R.addCopy(v);

            const N = try self.neighbors(v);
            defer self.allocator.free(N);

            var __P = try P.intersectCopy(N);
            defer __P.deinit();

            var __X = try X.intersectCopy(N);
            defer __X.deinit();

            if (try self.bronKerboschImpl(__R, __P, __X, cliques)) __R.deinit();

            P.remove(v);
            try X.add(v);
        }

        return true;
    }

    fn bronKerbosch(self: *const @This()) !std.ArrayList(Set) {
        var R = Set.init(self.allocator);
        defer R.deinit();
        var P = Set.init(self.allocator);
        defer P.deinit();

        for (self.nodes.items, 0..) |_, v| {
            try P.add(v);
        }

        var X = Set.init(self.allocator);
        defer X.deinit();

        var out = std.ArrayList(Set).init(self.allocator);

        _ = try self.bronKerboschImpl(R, P, X, &out);

        return out;
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("G = {{{s},\n{any}}}", .{ self.nodes.items, self.edges.items });
    }
};

fn part1(file: File, allocator: Allocator) !u64 {
    var graph = try Graph.init(file, allocator);
    defer graph.deinit();

    const tris = try graph.find_triangles();
    defer graph.allocator.free(tris);

    var count: usize = 0;
    for (tris) |t| {
        inline for (t.vertices) |v| {
            if (graph.nodes.items[v][0] == 't') {
                count += 1;
                break;
            }
        }
    }

    return count;
}

fn stringLessThan(_: void, lhs: [2]u8, rhs: [2]u8) bool {
    return std.mem.order(u8, &lhs, &rhs) == .lt;
}

fn part2(file: File, allocator: Allocator) ![]u8 {
    var graph = try Graph.init(file, allocator);
    defer graph.deinit();

    var result = try graph.bronKerbosch();
    defer {
        for (result.items, 0..) |_, i| result.items[i].deinit();
        result.deinit();
    }

    var max_size: usize = 0;
    var max_index: usize = undefined;

    for (result.items, 0..) |s, i| {
        if (max_size < s.items.count()) {
            max_size = s.items.count();
            max_index = i;
        }
    }

    var out = try allocator.alloc([2]u8, max_size);
    defer allocator.free(out);
    var it = result.items[max_index].items.keyIterator();
    var i: usize = 0;
    while (it.next()) |k| {
        out[i] = graph.nodes.items[k.*];
        i += 1;
    }

    std.mem.sort([2]u8, out, {}, stringLessThan);

    var ret = try allocator.alloc(u8, max_size * 3 - 1);
    for (out, 0..) |o, j| {
        const _j = j * 3;
        @memcpy(ret[_j..(_j+2)], &o);
        if (j != out.len - 1) ret[_j+2] = ',';
    }

    return ret;
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
        const result = try part2(file, allocator);
        defer allocator.free(result);
        std.debug.print("Part 2: {s}\n", .{ result });
    }
}

test "part 1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day23/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(7, result);
}

test "part 2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day23/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = try part2(file, allocator);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("co,de,ka,ta", result);
}
