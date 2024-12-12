const std = @import("std");
const Allocator = std.mem.Allocator;

const Solver = struct {
    const Vec2 = struct {
        x: i64,
        y: i64,
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
    const Plot = struct { id: u8, visited: bool };
    const PlotArea = struct { area: []Vec2, perimiter: u64 };
    const Error = Allocator.Error || error{ OutOfMemory, OutOfBounds, OtherPlot, Visited };

    allocator: Allocator,
    plots: []Plot,
    width: u64,
    height: u64,

    fn init(file: std.fs.File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.height = 0;
        self.width = 0;

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();
        const stat = try file.stat();

        var map = std.ArrayList(Plot).init(self.allocator);
        defer map.deinit();

        while (try reader.readUntilDelimiterOrEofAlloc(self.allocator, '\n', stat.size)) |line| {
            defer self.allocator.free(line);
            if (self.height == 0) self.width = line.len;
            for (line) |c| {
                try map.append(.{ .id = c, .visited = false });
            }
            self.height += 1;
        }

        self.plots = try map.toOwnedSlice();
        return self;
    }
    fn deinit(self: *@This()) void {
        self.allocator.free(self.plots);
    }

    fn outOfBounds(self: *@This(), i: i64, j: i64) bool {
        return !(0 <= i and i < self.height and 0 <= j and j < self.width);
    }

    fn index(self: *@This(), i: i64, j: i64) u64 {
        return @as(u64, @intCast(i)) * self.width + @as(u64, @intCast(j));
    }

    fn findPlotArea(self: *@This(), id: u8, i: i64, j: i64) Error!PlotArea {
        if (self.outOfBounds(i, j)) return error.OutOfBounds;
        const val: *Plot = &self.plots[@as(u64, @intCast(i)) * self.width + @as(u64, @intCast(j))];
        if (val.id != id) return error.OtherPlot;
        if (val.visited) return error.Visited;
        val.visited = true;

        var area = std.ArrayList(Vec2).init(self.allocator);
        defer area.deinit();
        try area.append(.{ .x = j, .y = i });
        var perimiter: u64 = 0;

        const inputs = [4]struct { i: i64, j: i64 }{
            .{ .i = i - 1, .j = j },
            .{ .i = i, .j = j - 1 },
            .{ .i = i + 1, .j = j },
            .{ .i = i, .j = j + 1 },
        };
        blk: for (inputs) |in| {
            const p = self.findPlotArea(id, in.i, in.j) catch |err| {
                switch (err) {
                    error.OutOfBounds, error.OtherPlot => {
                        perimiter += 1;
                    },
                    else => {},
                }
                continue :blk;
            };
            defer self.allocator.free(p.area);
            try area.appendSlice(p.area);
            perimiter += p.perimiter;
        }

        return .{ .area = try area.toOwnedSlice(), .perimiter = perimiter };
    }

    fn contains(pt: Vec2, points: []Vec2) bool {
        for (points) |p| {
            if (p.x == pt.x and p.y == pt.y) return true;
        }
        return false;
    }
    fn findPlotSides(self: *@This(), id: u8, points: []Vec2) Error!u64 {
        const Info = struct { new_edge: bool, edge_count: std.AutoHashMap(u64, u64) };
        var infos: [4]Info = [_]Info{.{ .new_edge = true, .edge_count = std.AutoHashMap(u64, u64).init(self.allocator) }} ** 4;
        defer {
            for (&infos) |*info| info.edge_count.deinit();
        }

        {
            var new_edge = try self.allocator.alloc(bool, self.width * 2);
            for (new_edge, 0..) |_, i| new_edge[i] = true;
            defer self.allocator.free(new_edge);

            var i: i64 = 0;
            while (i < self.height) : (i += 1) {
                var j: i64 = 0;
                infos[0].new_edge = true;
                infos[1].new_edge = true;
                while (j < self.width) : (j += 1) {
                    var in_area = contains(Vec2{ .x = j, .y = i }, points);
                    if (self.plots[self.index(i, j)].id == id and in_area) {
                        if (infos[0].new_edge) {
                            const value = try infos[0].edge_count.getOrPutValue(@as(u64, @intCast(j)), 0);
                            if (new_edge[@as(u64, @intCast(j))])
                                value.value_ptr.* += 1;

                            infos[0].new_edge = false;
                            new_edge[@as(u64, @intCast(j))] = false;
                        } else {
                            new_edge[@as(u64, @intCast(j))] = true;
                        }
                    } else {
                        infos[0].new_edge = true;
                        new_edge[@as(u64, @intCast(j))] = true;
                    }
                    in_area = contains(Vec2{
                        .x = @as(i64, @intCast(self.width)) - 1 - j,
                        .y = @as(i64, @intCast(self.height)) - 1 - i,
                    }, points);
                    if (self.plots[self.index(@as(i64, @intCast(self.height)) - 1 - i, @as(i64, @intCast(self.width)) - 1 - j)].id == id and in_area) {
                        if (infos[1].new_edge) {
                            const value = try infos[1].edge_count.getOrPutValue(self.width - 1 - @as(u64, @intCast(j)), 0);
                            if (new_edge[@as(u64, @intCast(j)) + self.width])
                                value.value_ptr.* += 1;

                            infos[1].new_edge = false;
                            new_edge[@as(u64, @intCast(j)) + self.width] = false;
                        } else {
                            new_edge[@as(u64, @intCast(j)) + self.width] = true;
                        }
                    } else {
                        infos[1].new_edge = true;
                        new_edge[@as(u64, @intCast(j)) + self.width] = true;
                    }
                }
            }
        }
        {
            var new_edge = try self.allocator.alloc(bool, self.height * 2);
            for (new_edge, 0..) |_, i| new_edge[i] = true;
            defer self.allocator.free(new_edge);
            var j: i64 = 0;
            while (j < self.width) : (j += 1) {
                var i: i64 = 0;
                infos[2].new_edge = true;
                infos[3].new_edge = true;
                while (i < self.height) : (i += 1) {
                    var in_area = contains(Vec2{ .x = j, .y = i }, points);
                    if (self.plots[self.index(i, j)].id == id and in_area) {
                        if (infos[2].new_edge) {
                            const value = try infos[2].edge_count.getOrPutValue(@as(u64, @intCast(i)), 0);
                            if (new_edge[@as(u64, @intCast(i))])
                                value.value_ptr.* += 1;
                            infos[2].new_edge = false;
                            new_edge[@as(u64, @intCast(i))] = false;
                        } else {
                            new_edge[@as(u64, @intCast(i))] = true;
                        }
                    } else {
                        infos[2].new_edge = true;
                        new_edge[@as(u64, @intCast(i))] = true;
                    }
                    in_area = contains(Vec2{
                        .x = @as(i64, @intCast(self.width)) - 1 - j,
                        .y = @as(i64, @intCast(self.height)) - 1 - i,
                    }, points);
                    if (self.plots[self.index(@as(i64, @intCast(self.height)) - 1 - i, @as(i64, @intCast(self.width)) - 1 - j)].id == id and in_area) {
                        if (infos[3].new_edge) {
                            const value = try infos[3].edge_count.getOrPutValue(self.height - 1 - @as(u64, @intCast(i)), 0);
                            if (new_edge[@as(u64, @intCast(i)) + self.height])
                                value.value_ptr.* += 1;

                            infos[3].new_edge = false;
                            new_edge[@as(u64, @intCast(i)) + self.height] = false;
                        } else {
                            new_edge[@as(u64, @intCast(i)) + self.height] = true;
                        }
                    } else {
                        infos[3].new_edge = true;
                        new_edge[@as(u64, @intCast(i)) + self.height] = true;
                    }
                }
            }
        }
        var sum: u64 = 0;
        for (infos) |info| {
            var it = info.edge_count.keyIterator();
            while (it.next()) |k| {
                const v = info.edge_count.get(k.*);
                sum += v.?;
            }
        }
        return sum;
    }
};

fn part1(file: std.fs.File, allocator: Allocator) !u64 {
    var solver = try Solver.init(file, allocator);
    defer solver.deinit();

    var perimiters = std.ArrayList(Solver.PlotArea).init(allocator);
    defer perimiters.deinit();
    var i: i64 = 0;
    while (i < solver.height) : (i += 1) {
        var j: i64 = 0;
        while (j < solver.width) : (j += 1) {
            const val: Solver.Plot = solver.plots[@as(u64, @intCast(i)) * solver.width + @as(u64, @intCast(j))];
            const v = solver.findPlotArea(val.id, i, j) catch continue;
            defer allocator.free(v.area);
            try perimiters.append(v);
        }
    }

    var sum: u64 = 0;
    for (perimiters.items) |v| {
        sum += v.area.len * v.perimiter;
    }
    return sum;
}

fn part2(file: std.fs.File, allocator: Allocator) !u64 {
    var solver = try Solver.init(file, allocator);
    defer solver.deinit();

    var perimiters = std.ArrayList(Solver.PlotArea).init(allocator);
    defer perimiters.deinit();
    var i: i64 = 0;
    while (i < solver.height) : (i += 1) {
        var j: i64 = 0;
        while (j < solver.width) : (j += 1) {
            const val: Solver.Plot = solver.plots[@as(u64, @intCast(i)) * solver.width + @as(u64, @intCast(j))];
            var v = solver.findPlotArea(val.id, i, j) catch continue;
            defer allocator.free(v.area);

            v.perimiter = try solver.findPlotSides(val.id, v.area);

            try perimiters.append(v);
        }
    }

    var sum: u64 = 0;
    for (perimiters.items) |v| {
        sum += v.area.len * v.perimiter;
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

test "part 1.1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day12/test_1.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(140, result);
}
test "part 1.2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day12/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(772, result);
}
test "part 1.3" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day12/test_3.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(1930, result);
}

test "part 2.1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day12/test_1.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(80, result);
}
test "part 2.2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day12/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(436, result);
}
test "part 2.3" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day12/test_3.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(1206, result);
}
test "part 2.4" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day12/test_4.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(236, result);
}
test "part 2.5" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day12/test_5.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part2(file, allocator);
    try std.testing.expectEqual(368, result);
}
