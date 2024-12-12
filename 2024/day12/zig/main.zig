const std = @import("std");
const Allocator = std.mem.Allocator;

const Solver = struct {
    const Plot = struct { id: u8, visited: bool };
    const PlotArea = struct { area: u64, perimiter: u64 };
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

    fn findPlotArea(self: *@This(), id: u8, i: i64, j: i64) error{ OutOfBounds, OtherPlot, Visited }!PlotArea {
        if (self.outOfBounds(i, j)) return error.OutOfBounds;
        const val: *Plot = &self.plots[@as(u64, @intCast(i)) * self.width + @as(u64, @intCast(j))];
        if (val.id != id) return error.OtherPlot;
        if (val.visited) return error.Visited;
        val.visited = true;
        var plot: PlotArea = .{ .area = 1, .perimiter = 0 };

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
                        plot.perimiter += 1;
                    },
                    else => {},
                }
                continue :blk;
            };
            plot.area += p.area;
            plot.perimiter += p.perimiter;
        }

        return plot;
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
            try perimiters.append(v);
        }
    }

    var sum: u64 = 0;
    for (perimiters.items) |v| {
        sum += v.area * v.perimiter;
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
