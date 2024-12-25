const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Solver = struct {
    const Gate = struct {
        const Type = enum { AND, OR, XOR };

        a: [3]u8,
        b: [3]u8,
        op: Type,
        out: [3]u8,

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            try writer.print("{s} {s} {s} -> {s}", .{ self.a, @tagName(self.op), self.b, self.out });
        }
    };
    allocator: Allocator,
    values: std.AutoArrayHashMap([3]u8, ?u1),
    gates: std.ArrayList(Gate),
    unprocessed: std.ArrayList(Gate),

    fn init(file: File, allocator: Allocator) !@This() {
        var self: @This() = undefined;
        self.allocator = allocator;
        self.values = std.AutoArrayHashMap([3]u8, ?u1).init(self.allocator);
        self.gates = std.ArrayList(Gate).init(self.allocator);
        self.unprocessed = std.ArrayList(Gate).init(self.allocator);

        var buffered_reader = std.io.bufferedReader(file.reader());
        const reader = buffered_reader.reader();

        var buffer: [64]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (line.len == 0) break;
            var split = std.mem.splitAny(u8, line, ": ");
            const identifier = if (split.next()) |s| [3]u8{ s[0], s[1], s[2] } else continue;
            _ = split.next() orelse continue;
            const v = if (split.next()) |s| @as(u1, @intCast(s[0] - 0x30)) else continue;

            try self.values.put(identifier, v);
        }

        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            var split = std.mem.splitAny(u8, line, " ");

            const a = if (split.next()) |s| [3]u8{ s[0], s[1], s[2] } else continue;
            if (self.values.get(a) == null) try self.values.put(a, null);

            const op: Gate.Type = if (split.next()) |s|
                if (std.mem.eql(u8, "OR", s)) .OR else if (std.mem.eql(u8, "AND", s)) .AND else if (std.mem.eql(u8, "XOR", s)) .XOR else continue
            else
                continue;

            const b = if (split.next()) |s| [3]u8{ s[0], s[1], s[2] } else continue;
            if (self.values.get(b) == null) try self.values.put(b, null);

            _ = split.next() orelse continue;

            const out = if (split.next()) |s| [3]u8{ s[0], s[1], s[2] } else continue;
            if (self.values.get(out) == null) try self.values.put(out, null);

            try self.gates.append(.{ .a = a, .b = b, .op = op, .out = out });
            try self.unprocessed.append(.{ .a = a, .b = b, .op = op, .out = out });
        }

        return self;
    }

    fn deinit(self: *@This()) void {
        self.values.deinit();
        self.gates.deinit();
        self.unprocessed.deinit();
    }

    fn processGates(self: *@This()) !void {
        while (self.unprocessed.items.len > 0) {
            for (self.unprocessed.items, 0..) |gate, i| {
                if (try self.processGate(gate)) {
                    _ = self.unprocessed.swapRemove(i);
                    break;
                }
            }
        }
    }

    fn processGate(self: *@This(), gate: Gate) !bool {
        if (self.values.get(gate.a).? == null or self.values.get(gate.b).? == null) return false;
        const a = self.values.get(gate.a).?.?;
        const b = self.values.get(gate.b).?.?;
        const v = switch (gate.op) {
            .AND => a & b,
            .OR => a | b,
            .XOR => a ^ b,
        };
        try self.values.put(gate.out, v);
        return true;
    }
};

fn stringLessThan(_: void, lhs: [3]u8, rhs: [3]u8) bool {
    return std.mem.order(u8, &lhs, &rhs) == .lt;
}

fn part1(file: File, allocator: Allocator) !u64 {
    var solver = try Solver.init(file, allocator);
    defer solver.deinit();

    try solver.processGates();

    const keys = try allocator.dupe([3]u8, solver.values.keys());
    defer allocator.free(keys);

    std.mem.sort([3]u8, keys, {}, stringLessThan);

    var sum: usize = 0;
    var count: usize = 0;
    for (keys) |k| {
        if (k[0] != 'z') continue;
        sum += solver.values.get(k).?.? * try std.math.powi(usize, 2, count);
        count += 1;
    }

    return sum;
}

fn dedup(arr: *std.ArrayList([3]u8)) void {
    var i: usize = 0;
    outer: while (i < arr.items.len) {
        for (arr.items[(i + 1)..]) |v| {
            if (std.mem.eql(u8, &arr.items[i], &v)) {
                _ = arr.swapRemove(i);
                continue :outer;
            }
        }
        i += 1;
    }
}

fn part2(file: File, allocator: Allocator) ![]const u8 {
    var solver = try Solver.init(file, allocator);
    defer solver.deinit();

    var incorrect = std.ArrayList([3]u8).init(allocator);
    defer incorrect.deinit();

    for (solver.gates.items) |gate| {
        if (gate.out[0] == 'z' and gate.op != .XOR and !std.mem.eql(u8, &gate.out, "z45")) {
            try incorrect.append(gate.out);
            continue;
        }
        if (gate.out[0] != 'z' and gate.op == .XOR and !(gate.a[0] == 'x' or gate.a[0] == 'y')) {
            try incorrect.append(gate.out);
            continue;
        }

        switch (gate.op) {
            .OR => {
                const lhs_feeds: Solver.Gate = lhs: for (solver.gates.items) |g| {
                    if (std.mem.eql(u8, &g.out, &gate.a)) break :lhs g;
                } else unreachable;
                if (lhs_feeds.op != .AND) {
                    try incorrect.append(lhs_feeds.out);
                }
                const rhs_feeds: Solver.Gate = rhs: for (solver.gates.items) |g| {
                    if (std.mem.eql(u8, &g.out, &gate.b)) break :rhs g;
                } else unreachable;
                if (rhs_feeds.op != .AND) {
                    try incorrect.append(rhs_feeds.out);
                }
            },
            .AND => {
                if (!(std.mem.eql(u8, &gate.a, "x00") or std.mem.eql(u8, &gate.b, "x00"))) {
                    var feeds = std.ArrayList(Solver.Gate).init(allocator);
                    defer feeds.deinit();
                    for (solver.gates.items) |g| {
                        if (std.mem.eql(u8, &g.a, &gate.out) or std.mem.eql(u8, &g.b, &gate.out)) try feeds.append(g);
                    }
                    for (feeds.items) |fed| {
                        if (fed.op != .OR) {
                            try incorrect.append(gate.out);
                            break;
                        }
                    }
                }
            },
            else => {},
        }
    }

    dedup(&incorrect);
    std.mem.sort([3]u8, incorrect.items, {}, stringLessThan);

    var result = try allocator.alloc(u8, incorrect.items.len * 4 - 1);
    for (incorrect.items, 0..) |s, i| {
        if (i != incorrect.items.len - 1) result[i * 4 + 3] = ',';
        @memcpy(result[(i * 4)..(i * 4 + 3)], &s);
    }

    return result;
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
        std.debug.print("Part 2: {s}\n", .{result});
    }
}

test "part 1.1" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day24/test.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(4, result);
}

test "part 1.2" {
    const file = std.fs.cwd().openFile("../../../inputs/2024/day24/test_2.txt", .{ .mode = .read_only }) catch return error.FileNotFound;
    defer file.close();
    const allocator = std.testing.allocator;
    const result = part1(file, allocator);
    try std.testing.expectEqual(2024, result);
}
